import QtQuick
import qs.Commons

// Read-only rendered filter line. The owning module tracks the text and
// handles key events itself so arrow keys and Enter stay with the list.
Item {
  id: root
  property string text: ""
  property string placeholder: "Search…"
  property string icon: "󰍉"
  implicitHeight: Math.max(Theme.fontTitle + Theme.space * 2, 36)

  Row {
    anchors.fill: parent
    anchors.leftMargin: Theme.space
    anchors.rightMargin: Theme.space
    spacing: Theme.space

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontTitle
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.text.length > 0 ? root.text : root.placeholder
      color: root.text.length > 0 ? Theme.foreground : Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontTitle
      elide: Text.ElideLeft
      width: parent.width - parent.spacing - Theme.fontTitle * 2
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 2
      height: Theme.fontTitle
      color: Theme.accent
      visible: root.text.length > 0
      x: -Theme.space
    }
  }
}
