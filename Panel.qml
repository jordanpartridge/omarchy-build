import QtQuick
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

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    opened ? close() : open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(Style.space(160))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
    }

    Column {
      anchors.fill: parent
      anchors.margins: Style.space(16)
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
        width: parent.width
        wrapMode: Text.Wrap
        text: "Timeline daemon is not running yet. This panel is the bar stub. Sessions, Tailscale SSH, send, and chapter retry ship in the daemon, not in the shell."
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.size
        textFormat: Text.PlainText
      }
    }
  }
}
