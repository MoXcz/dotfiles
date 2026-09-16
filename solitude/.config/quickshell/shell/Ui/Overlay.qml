import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// Full-screen layer surface on the focused monitor with a click-to-dismiss
// scrim and exclusive keyboard focus while open. Modules place their card
// inside and handle keys on it.
PanelWindow {
  id: root

  property bool opened: false
  property string namespace: "shell-overlay"
  // Attached surfaces leave the shell chrome uncovered by their scrim.
  property int scrimTopInset: 0
  default property alias content: contentItem.data
  signal dismissed()

  visible: opened
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: root.namespace
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // Follow the focused monitor when opening.
  function focusedScreen() {
    var monitor = Hyprland.focusedMonitor
    var screens = Quickshell.screens
    if (monitor) {
      for (var i = 0; i < screens.length; i++) {
        if (screens[i].name === monitor.name) return screens[i]
      }
    }
    return screens.length > 0 ? screens[0] : null
  }

  onOpenedChanged: if (opened) root.screen = focusedScreen()

  Rectangle {
    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom }
    anchors.topMargin: root.scrimTopInset
    color: Theme.scrim
    MouseArea {
      anchors.fill: parent
      onClicked: root.dismissed()
    }
  }

  Item {
    id: contentItem
    anchors.fill: parent
  }
}
