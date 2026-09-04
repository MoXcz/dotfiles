import QtQuick
import Quickshell.Hyprland
import qs.Commons

// Title of the focused window, cut with an ellipsis past
// Config.bar.activeWindowMaxWidth. The toplevel handle is preferred; the
// activewindow IPC event covers the moments when it is not available.
Item {
  id: root

  // Read by WidgetSlot; binding visible directly would loop through the Loader.
  property bool shown: title !== ""

  property string eventTitle: ""
  readonly property string title: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : eventTitle

  implicitWidth: Math.min(text.implicitWidth, Config.bar.activeWindowMaxWidth) + Theme.space * 2

  // Thin divider between the workspaces and the title.
  Rectangle {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Theme.borderWidth
    height: parent.height * 0.45
    color: Theme.border
  }

  Text {
    id: text
    anchors.left: parent.left
    anchors.leftMargin: Theme.space
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, Config.bar.activeWindowMaxWidth)
    text: root.title
    color: Theme.muted
    elide: Text.ElideRight
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activewindow") root.eventTitle = event.parse(2)[1] || ""
    }
  }
}
