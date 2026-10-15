import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "jordan.build"
  ipcTarget: "jordan.build"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string daemonUrl: "http://127.0.0.1:18765/sessions"
  property string daemonState: "checking"
  property string daemonDetail: "Checking the local daemon."
  property var sessions: []

  readonly property color contentForeground: bar ? bar.foreground : Commons.Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    root.reload()
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function sessionTitle(item) {
    if (!item) return "(no name)"
    if (item.name) return String(item.name)
    if (item.id) return String(item.id)
    return "(no name)"
  }

  function sessionLine(item) {
    if (!item) return ""
    var parts = []
    if (item.state) parts.push(String(item.state))
    if (item.host) parts.push(String(item.host))
    if (item.summary) parts.push(String(item.summary))
    return parts.join(", ")
  }

  function reload() {
    root.daemonState = "checking"
    root.daemonDetail = "Checking the local daemon."
    var req = new XMLHttpRequest()
    req.open("GET", root.daemonUrl)
    req.onreadystatechange = function() {
      if (req.readyState !== XMLHttpRequest.DONE) return
      if (req.status === 0) {
        root.daemonState = "down"
        root.daemonDetail = "Not reachable at 127.0.0.1:18765. From this plugin's checkout, run python3 daemon/server.py."
        root.sessions = []
        return
      }
      if (req.status !== 200) {
        root.daemonState = "error"
        root.daemonDetail = "The daemon replied with HTTP " + req.status + "."
        root.sessions = []
        return
      }
      var data
      try {
        data = JSON.parse(req.responseText)
      } catch (e) {
        root.daemonState = "error"
        root.daemonDetail = "The daemon replied, but the body was not JSON."
        root.sessions = []
        return
      }
      if (!data || !Array.isArray(data.sessions)) {
        root.daemonState = "error"
        root.daemonDetail = "The daemon replied, but it did not return a session list."
        root.sessions = []
        return
      }
      root.sessions = data.sessions
      root.daemonState = "up"
      if (data.ingest === "not_implemented" && data.sessions.length === 0) {
        root.daemonDetail = "Daemon is up at 127.0.0.1:18765. It is not reading agent transcripts. The session list is empty."
      } else if (data.sessions.length === 0) {
        root.daemonDetail = "Daemon is up at 127.0.0.1:18765. It reported no sessions."
      } else {
        root.daemonDetail = "Daemon is up at 127.0.0.1:18765. Showing the sessions it reported."
      }
    }
    req.send()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(10)

        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: "Omarchy Build"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.subtitle
            font.weight: Font.DemiBold
            textFormat: Text.PlainText
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Early"
            color: Commons.Color.accent
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            font.weight: Font.Bold
            textFormat: Text.PlainText
          }
        }

        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: "This panel asks 127.0.0.1:18765 for sessions. It does not read agent transcripts."
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.body
          textFormat: Text.PlainText
        }

        Text {
          width: parent.width
          wrapMode: Text.Wrap
          text: root.daemonDetail
          color: Qt.darker(root.contentForeground, 1.35)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          textFormat: Text.PlainText
        }

        Repeater {
          model: root.sessions

          delegate: Column {
            width: column.width
            spacing: Style.space(2)

            Text {
              width: parent.width
              wrapMode: Text.Wrap
              text: root.sessionTitle(modelData)
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              textFormat: Text.PlainText
            }

            Text {
              width: parent.width
              visible: text !== ""
              wrapMode: Text.Wrap
              text: root.sessionLine(modelData)
              color: Qt.darker(root.contentForeground, 1.35)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              textFormat: Text.PlainText
            }
          }
        }

        Text {
          text: "Refresh"
          color: Commons.Color.accent
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.body
          font.underline: true
          textFormat: Text.PlainText

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.reload()
          }
        }
      }
    }
  }
}
