import QtQuick
import qs.Commons

// Draggable 0..1 bar. Emits `moved` while dragging; the owner writes the
// value back so the fill tracks the real level.
Item {
  id: root

  property real value: 0
  property bool dim: false
  signal moved(value: real)

  implicitHeight: 14

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 4
    radius: 2
    color: Theme.surfaceAlt

    Rectangle {
      id: fill
      width: Math.round(parent.width * Util.clamp(root.value, 0, 1))
      height: parent.height
      radius: parent.radius
      color: root.dim ? Theme.muted : Theme.accent
    }
  }

  Rectangle {
    width: 10
    height: 10
    radius: 5
    anchors.verticalCenter: parent.verticalCenter
    x: Util.clamp(fill.width - width / 2, 0, root.width - width)
    color: area.containsMouse || area.pressed ? Theme.foreground : (root.dim ? Theme.muted : Theme.accent)
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    function update(mx) { root.moved(Util.clamp(mx / width, 0, 1)) }
    onPressed: function(mouse) { update(mouse.x) }
    onPositionChanged: function(mouse) { if (pressed) update(mouse.x) }
  }
}
