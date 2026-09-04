import QtQuick
import qs.Commons

// Full-width footer action.
Rectangle {
  id: root

  property string text: ""
  property string icon: ""
  property bool highlighted: false     // keyboard cursor is on this button
  signal clicked()

  width: parent ? parent.width : implicitWidth
  implicitHeight: Theme.fontBody + Theme.space * 2
  radius: Theme.cornerRadius
  color: area.containsMouse ? Theme.hover : Theme.surfaceAlt
  border.color: highlighted ? Theme.accent : Theme.border
  border.width: Theme.borderWidth

  Row {
    anchors.centerIn: parent
    spacing: Theme.spaceSm
    Text {
      visible: root.icon !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontIcon
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    onClicked: root.clicked()
  }
}
