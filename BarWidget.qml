import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "jordan.build"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }
  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }
  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.opened
    tooltipText: "Omarchy Build · session control"
    iconComponent: Component {
      Item {
        Text {
          anchors.centerIn: parent
          // brain / build glyph — not ollama robot
          text: "󰘦"
          color: root.bar ? root.bar.barForeground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.bar.iconFont
          renderType: Text.NativeRendering
          textFormat: Text.PlainText
        }
      }
    }
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.togglePanel()
    }
  }
}
