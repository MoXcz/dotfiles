import QtQuick
import qs.Commons

// Hand-rolled on/off switch. The owner applies the change from `toggled`
// so the pill follows the real state rather than a local copy.
Item {
  id: root

  property bool checked: false
  signal toggled(value: bool)

  implicitWidth: 34
  implicitHeight: 18
  opacity: enabled ? 1 : 0.4

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.checked ? Theme.accent : Theme.surfaceAlt
    border.color: root.checked ? Theme.accent : Theme.border
    border.width: Theme.borderWidth

    Rectangle {
      readonly property int inset: 3
      width: parent.height - inset * 2
      height: width
      radius: width / 2
      y: inset
      x: root.checked ? parent.width - width - inset : inset
      color: root.checked ? Theme.background : Theme.muted
      Behavior on x { NumberAnimation { duration: 90 } }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.toggled(!root.checked)
  }
}
