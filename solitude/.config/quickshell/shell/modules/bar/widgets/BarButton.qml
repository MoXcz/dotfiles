import QtQuick
import qs.Commons

// Hoverable bar cell with an optional glyph and a label. Widgets that are a
// single clickable readout extend this directly.
Item {
  id: root

  property string icon: ""
  property string label: ""
  property color textColor: Theme.foreground
  property color iconColor: textColor
  property color fill: "transparent"
  property bool interactive: true
  property bool panelActive: false
  property int paddingX: Theme.space

  signal clicked(button: int)
  signal scrolled(delta: int)

  implicitWidth: row.implicitWidth + paddingX * 2
  implicitHeight: row.implicitHeight + Theme.spaceSm * 2

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: Theme.spaceSm
    anchors.bottomMargin: Theme.spaceSm
    // Pill-shaped, so the highlight follows the dock it sits in.
    radius: height / 2
    color: root.panelActive || area.pressed ? Theme.selected
         : root.interactive && area.containsMouse ? Theme.hover : root.fill
    Behavior on color { ColorAnimation { duration: 70 } }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Theme.spaceSm

    Text {
      visible: root.icon !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      color: root.iconColor
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontIcon
    }

    Text {
      visible: root.label !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      color: root.textColor
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: function(event) { root.clicked(event.button) }
    onWheel: function(event) { root.scrolled(event.angleDelta.y) }
  }
}
