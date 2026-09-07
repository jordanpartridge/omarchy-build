import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "jordan.build"
  ipcTarget: "jordan.build"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // Live sessions loaded from the Omarchy‑Build daemon
  ListModel {
    id: sessionModel
  }
  property int selected: 0
  // convenience accessor for the currently selected session object
  function currentSession() {
    return sessionModel.get(selected) || {}
  }
  // Load sessions from the daemon into the ListModel
  function loadSessions() {
    const req = new XMLHttpRequest()
    req.open('GET', 'http://127.0.0.1:18765/sessions')
    req.onreadystatechange = function() {
      if (req.readyState === 4 && req.status === 200) {
        const data = JSON.parse(req.responseText)
        sessionModel.clear()
        for (let i = 0; i < data.sessions.length; i++) {
          sessionModel.append(data.sessions[i])
        }
        // reset selection after reload
        selected = 0
      }
    }
    req.send()
  }

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { opened ? close() : open() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function demoToast(msg) {
    if (root.bar && root.bar.run)
      root.bar.run("omarchy-notification-send " + JSON.stringify("Build demo · " + msg))
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(Style.space(460))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
    }

    Column {
      anchors.fill: parent
      anchors.margins: Style.space(16)
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(8)
        Text {
          text: "Omarchy Build"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.size
          font.weight: Font.DemiBold
          textFormat: Text.PlainText
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "DEMO"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.size * 0.85
          font.weight: Font.Bold
          textFormat: Text.PlainText
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.Wrap
        text: "Session control plane preview. Daemon not running — actions toast only."
        color: Qt.darker(Color.foreground, 1.4)
        font.family: Style.font.family
        font.pixelSize: Style.font.size * 0.9
        textFormat: Text.PlainText
      }

      // session list
      Repeater {
        model: root.demoSessions
        delegate: Rectangle {
          width: parent.width
          height: Style.space(44)
          radius: Style.space(6)
          color: index === root.selected ? Style.selectedFillFor(Color.accent, Color.accent) : Color.popups.background
          border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
          border.width: 1
          MouseArea {
            anchors.fill: parent
            onClicked: root.selected = index
          }
          Row {
            anchors.fill: parent
            anchors.margins: Style.space(10)
            spacing: Style.space(10)
            Text {
              text: modelData.state
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.size * 0.8
              font.weight: Font.DemiBold
              width: Style.space(64)
              textFormat: Text.PlainText
            }
            Column {
              Text {
                text: modelData.name
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.size
                textFormat: Text.PlainText
              }
              Text {
                text: modelData.host + " · " + modelData.summary
                color: Qt.darker(Color.foreground, 1.5)
                font.family: Style.font.family
                font.pixelSize: Style.font.size * 0.8
                textFormat: Text.PlainText
              }
            }
          }
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.Wrap
        text: "Selected: " + (session ? session.name : "")
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.size
        font.weight: Font.DemiBold
        textFormat: Text.PlainText
      }

      // control plane actions
      Grid {
        width: parent.width
        columns: 2
        rowSpacing: Style.space(8)
        columnSpacing: Style.space(8)

        Repeater {
          model: [
            { id: "recall", label: "Recall / send" },
            { id: "summarize", label: "Summarize (local)" },
            { id: "spawn", label: "Spawn session" },
            { id: "rollback", label: "Rollback chapter" },
            { id: "rollforward", label: "Rollforward" },
            { id: "anomaly", label: "Anomaly → PFC" },
            { id: "lagging", label: "Lagging idea → PFC" }
          ]
          delegate: Button {
            text: modelData.label
            width: (parent.width - Style.space(8)) / 2
            onClicked: {
                // map button ids to daemon endpoints
                const sid = root.currentSession().id
                if (!sid) { root.demoToast("No session selected"); return }
                if (modelData.id === "recall" || modelData.id === "send") {
                    // for demo we just send a generic message
                    const payload = {"message": "demo message"}
                    const req = new XMLHttpRequest()
                    req.open("POST", `http://127.0.0.1:18765/sessions/${sid}/send`)
                    req.setRequestHeader('Content-Type', 'application/json')
                    req.onreadystatechange = function() { if (req.readyState === 4) { root.demoToast(modelData.label + " – " + (req.status===200?"ok":"fail")) } }
                    req.send(JSON.stringify(payload))
                } else if (modelData.id === "summarize") {
                    const req = new XMLHttpRequest()
                    req.open("POST", `http://127.0.0.1:18765/sessions/${sid}/summarize`)
                    req.setRequestHeader('Content-Type', 'application/json')
                    req.onreadystatechange = function() { if (req.readyState === 4) { root.demoToast(modelData.label + " – " + (req.status===200?"ok":"fail")) } }
                    req.send()
                } else if (modelData.id === "spawn") {
                    const payload = {"name": "New demo", "host": "thor", "user": "jordan"}
                    const req = new XMLHttpRequest()
                    req.open("POST", `http://127.0.0.1:18765/sessions`)
                    req.setRequestHeader('Content-Type', 'application/json')
                    req.onreadystatechange = function() { if (req.readyState === 4 && req.status===201) { root.demoToast("Spawned"); root.loadSessions() } }
                    req.send(JSON.stringify(payload))
                } else if (modelData.id === "rollback") {
                    const req = new XMLHttpRequest()
                    req.open("POST", `http://127.0.0.1:18765/sessions/${sid}/rollback`)
                    req.setRequestHeader('Content-Type', 'application/json')
                    req.onreadystatechange = function() { if (req.readyState === 4) { root.demoToast(modelData.label + " – " + (req.status===200?"ok":"fail")) } }
                    req.send()
                } else if (modelData.id === "rollforward") {
                    const req = new XMLHttpRequest()
                    req.open("POST", `http://127.0.0.1:18765/sessions/${sid}/rollforward`)
                    req.setRequestHeader('Content-Type', 'application/json')
                    req.onreadystatechange = function() { if (req.readyState === 4) { root.demoToast(modelData.label + " – " + (req.status===200?"ok":"fail")) } }
                    req.send()
                } else if (modelData.id === "anomaly") {
                    // simply fetch anomalies and toast count
                    const req = new XMLHttpRequest()
                    req.open("GET", `http://127.0.0.1:18765/anomalies`)
                    req.onreadystatechange = function() { if (req.readyState === 4) { const data = JSON.parse(req.responseText); root.demoToast("Anomalies: " + data.anomalies.length) } }
                    req.send()
                } else if (modelData.id === "lagging") {
                    const req = new XMLHttpRequest()
                    req.open("GET", `http://127.0.0.1:18765/lagging-ideas`)
                    req.onreadystatechange = function() { if (req.readyState === 4) { const data = JSON.parse(req.responseText); root.demoToast("Lagging ideas: " + data.ideas.length) } }
                    req.send()
                }
            }
          }
        }
      }
    }
  }
}
