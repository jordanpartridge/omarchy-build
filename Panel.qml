import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "jordan.build"
  ipcTarget: "jordan.build"
  manageIpc: false

  PanelHero {
    id: hero
      bar: root.bar
      barForeground: bar ? bar.foreground : Color.foreground
      visible: false
    }

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  ListModel { id: sessionModel }
  property int selected: 0
  
  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }
  property bool daemonUp: false
  property string statusLine: "Connecting to daemon…"
  property string pendingKind: ""
  property string pendingLabel: ""
  readonly property var session: currentSession()

  function currentSession() {
    if (selected < 0 || selected >= sessionModel.count) return ({})
    return sessionModel.get(selected) || ({})
  }

  function applySessions(raw) {
    var data
    try { data = JSON.parse(String(raw || "").trim()) } catch (e) {
      root.daemonUp = false
      root.statusLine = "Daemon returned invalid JSON"
      return
    }
    var list = data && data.sessions ? data.sessions : []
    sessionModel.clear()
    var n = Math.min(list.length, 24)
    for (var i = 0; i < n; i++) {
      var s = list[i] || {}
      sessionModel.append({
        sid: String(s.id || ""),
        name: String(s.name || "Unnamed"),
        host: String(s.host || "?"),
        sessState: String(s.state || "next"),
        summary: String(s.summary || ""),
        live: s.live === true,
        paneId: String(s.pane_id || "")
      })
    }
    if (root.selected >= sessionModel.count) root.selected = 0
    root.daemonUp = true
    var q = (typeof searchField !== "undefined" && searchField) ? String(searchField.text || "").trim() : ""
    root.statusLine = sessionModel.count + " session" + (sessionModel.count === 1 ? "" : "s")
      + (q !== "" ? " matching “" + q + "”" : " from daemon")
  }

  function loadSessions() {
    if (fetchProc.running) return
    var q = ""
    if (typeof searchField !== "undefined" && searchField)
      q = String(searchField.text || "").trim().slice(0, 80)
    var url = "http://127.0.0.1:18765/sessions"
    if (q !== "") url += "?q=" + encodeURIComponent(q)
    fetchProc.command = ["curl", "-sS", "--max-time", "3", url]
    fetchProc.running = true
  }

  function moveSelection(dy) {
    if (sessionModel.count < 1) return
    var next = root.selected + dy
    if (next < 0) next = 0
    if (next > sessionModel.count - 1) next = sessionModel.count - 1
    root.selected = next
    root.ensureVisible()
  }

  function ensureVisible() {
    if (typeof sessionFlick === "undefined" || !sessionFlick) return
    var rowH = Style.space(44)
    var y = root.selected * rowH
    if (y < sessionFlick.contentY)
      sessionFlick.contentY = Math.max(0, y)
    var viewBottom = sessionFlick.contentY + sessionFlick.height
    if (y + rowH > viewBottom)
      sessionFlick.contentY = Math.max(0, y + rowH - sessionFlick.height)
  }

  function runCurl(kind, label, args) {
    if (actionProc.running) return
    root.pendingKind = kind
    root.pendingLabel = label
    root.statusLine = label + "…"
    actionProc.command = args
    actionProc.running = true
  }

  function doAction(action) {
    var sid = String(root.currentSession().sid || "")
    if (action === "spawn") {
      runCurl("mutate", "Spawn", ["curl", "-sS", "--max-time", "40", "-H", "Content-Type: application/json", "-d", "{\"cwd\":\"/home/jordan/Work\",\"name\":\"spawn\"}", "http://127.0.0.1:18765/sessions"])
      return
    }
    if (action === "anomaly") {
      runCurl("anomalies", "Anomalies", ["curl", "-sS", "--max-time", "5", "http://127.0.0.1:18765/anomalies"])
      return
    }
    if (action === "lagging") {
      runCurl("ideas", "Lagging ideas", ["curl", "-sS", "--max-time", "5", "http://127.0.0.1:18765/lagging-ideas"])
      return
    }
    if (!sid) {
      root.statusLine = "No session selected"
      return
    }
    if (action === "recall") {
      var msg = ""
      if (typeof injectField !== "undefined" && injectField && injectField.text)
        msg = String(injectField.text).slice(0, 240)
      if (msg) {
        runCurl("mutate", "Send", ["curl", "-sS", "--max-time", "10", "-H", "Content-Type: application/json", "-d", JSON.stringify({ message: msg }), "http://127.0.0.1:18765/sessions/" + sid + "/send"])
      } else {
        runCurl("mutate", "Recall", ["curl", "-sS", "--max-time", "40", "-X", "POST", "http://127.0.0.1:18765/sessions/" + sid + "/recall"])
      }
    } else if (action === "summarize") {
      runCurl("mutate", "Summarize", ["curl", "-sS", "--max-time", "5", "-X", "POST", "http://127.0.0.1:18765/sessions/" + sid + "/summarize"])
    } else if (action === "rollback") {
      runCurl("mutate", "Rollback", ["curl", "-sS", "--max-time", "5", "-X", "POST", "http://127.0.0.1:18765/sessions/" + sid + "/rollback"])
    } else if (action === "rollforward") {
      runCurl("mutate", "Rollforward", ["curl", "-sS", "--max-time", "5", "-X", "POST", "http://127.0.0.1:18765/sessions/" + sid + "/rollforward"])
    }
  }

  function applyAction(raw) {
    var kind = root.pendingKind
    var label = root.pendingLabel
    var data = {}
    try { data = JSON.parse(String(raw || "").trim()) } catch (e) { data = {} }
    if (data.error) {
      root.statusLine = label + " · " + String(data.error)
      return
    }
    if (kind === "anomalies") {
      var anomalies = data.anomalies || []
      root.statusLine = "Anomalies: " + anomalies.length
    } else if (kind === "ideas") {
      var ideas = data.ideas || []
      root.statusLine = "Lagging ideas: " + ideas.length
    } else if (kind === "mutate") {
      root.statusLine = String(data.status || label + " ok")
      if (data.status === "focused" || data.status === "resumed")
        root.close()
      else
        loadSessions()
    } else {
      root.statusLine = label + " ok"
    }
  }

  function open() {
    root.controller.show()
    loadSessions()
  }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? close() : open() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setBarForeground(value) {
    if (root.bar && "barForeground" in root.bar)
      root.bar.barForeground = value
  }

  Component.onCompleted: loadSessions()

  Process {
    id: fetchProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applySessions(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.daemonUp = false
        root.statusLine = "Daemon not running on 127.0.0.1:18765"
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyAction(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.statusLine = root.pendingLabel + " failed"
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    centerOnBar: true
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: (typeof searchField !== "undefined" && searchField && searchField.activeFocus)
               || (typeof injectField !== "undefined" && injectField && injectField.activeFocus)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.moveSelection(dy)
      }
      onActivateRequested: root.doAction("recall")
      onTextKey: function(t) {
        if (t === "/") {
          if (searchField) searchField.forceActiveFocus()
          return
        }
      }
    }

    Column {
      id: bodyCol
      anchors.fill: parent
      anchors.margins: Style.space(16)
      spacing: Style.space(8)

      Row {
        width: parent.width
        spacing: Style.space(8)
        Text {
          text: "Omarchy Build"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: 14
          font.weight: Font.DemiBold
          textFormat: Text.PlainText
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.daemonUp ? "LIVE" : "OFFLINE"
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: 12
          font.weight: Font.Bold
          textFormat: Text.PlainText
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.Wrap
        text: root.statusLine
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: 13
        textFormat: Text.PlainText
      }

      TextField {
        id: searchField
        width: parent.width
        placeholderText: "Search sessions  ·  / to focus  ·  j k to move"
        maximumLength: 80
        onTextChanged: searchDebounce.restart()
        Keys.onEscapePressed: function(event) {
          if (searchField.text !== "") {
            searchField.text = ""
            event.accepted = true
          } else {
            keyCatcher.forceActiveFocus()
            event.accepted = true
          }
        }
        Keys.onReturnPressed: function(event) {
          keyCatcher.forceActiveFocus()
          event.accepted = true
        }
        Keys.onDownPressed: function(event) {
          keyCatcher.forceActiveFocus()
          root.moveSelection(1)
          event.accepted = true
        }
      }

      Timer {
        id: searchDebounce
        interval: 220
        repeat: false
        onTriggered: root.loadSessions()
      }

      Flickable {
        id: sessionFlick
        width: parent.width
        height: Style.space(220)
        clip: true
        contentWidth: width
        contentHeight: sessionCol.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: sessionCol
          width: sessionFlick.width
          spacing: Style.space(4)

      Repeater {
        model: sessionModel
        delegate: Rectangle {
          width: parent.width
          height: Style.space(44)
          radius: Style.space(6)
          color: index === root.selected ? Style.selectedFillFor(Color.accent, Color.accent) : Color.popups.background
          border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
          border.width: 1
          MouseArea {
            anchors.fill: parent
            onClicked: {
              root.selected = index
            }
          }
          Row {
            anchors.fill: parent
            anchors.margins: Style.space(10)
            spacing: Style.space(10)
            Text {
              text: sessState
              color: Color.accent
              font.family: Style.font.family
                font.pixelSize: 11
              font.weight: Font.DemiBold
              width: Style.space(64)
              textFormat: Text.PlainText
            }
            Column {
              Text {
                text: name
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: 14
                textFormat: Text.PlainText
              }
              Text {
                text: (live ? "herdr " : "") + host + " · " + summary
                color: Color.foreground
                font.family: Style.font.family
              font.pixelSize: 11
                textFormat: Text.PlainText
              }
            }
          }
        }
      }
        }
      }

      Text {
        width: parent.width
        wrapMode: Text.Wrap
        text: session && session.name ? session.name : ""
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: 14
        font.weight: Font.DemiBold
        textFormat: Text.PlainText
      }

      TextField {
        id: injectField
        width: parent.width
        placeholderText: "Inject line (empty Recall = focus pane)"
        maximumLength: 240
        Keys.onEscapePressed: function(event) {
          keyCatcher.forceActiveFocus()
          event.accepted = true
        }
      }

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
            onClicked: root.doAction(modelData.id)
          }
        }
      }
    }
  }
}
