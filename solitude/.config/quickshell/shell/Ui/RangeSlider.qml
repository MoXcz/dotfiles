import QtQuick
import qs.Commons

// Ranged horizontal slider (omarchy's PanelSlider, renamed so it cannot
// shadow the 0..1 slider in modules/bar/panels). `moved` fires during
// the drag, `released` once at the end; the owner writes `value` back so
// the fill tracks the real level. Carries a range and integer snapping.
Item {
  id: root

  property var bar: null              // accepted for API parity; unused
  property real value: 0
  property real minimum: 0
  property real maximum: 1
  property real step: 0.05
  property bool integer: false
  property color trackColor: Theme.surfaceAlt
  property color fillColor: Theme.accent
  property color knobColor: Theme.accent
  property bool dragging: false
  property real trackHeight: 4
  property real knobSize: 12
  property real liveValue: value
  property int tickCount: 0
  property color tickColor: Theme.surface

  onValueChanged: if (!dragging) liveValue = value

  signal moved(real value)
  signal released(real value)
  signal rightClicked()

  implicitWidth: 200
  implicitHeight: Math.max(22, knobSize + Style.spacing.md)
  opacity: enabled ? 1 : 0.45

  readonly property real range: Math.max(0.0001, maximum - minimum)
  readonly property real progress: Math.max(0, Math.min(1, (liveValue - minimum) / range))
  readonly property bool _hot: mouseArea.containsMouse || root.dragging

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.trackHeight
    radius: height / 2
    color: root.trackColor
  }

  Rectangle {
    anchors.verticalCenter: track.verticalCenter
    anchors.left: track.left
    height: track.height
    radius: track.radius
    color: root.fillColor
    width: track.width * root.progress

    Behavior on width {
      enabled: !root.dragging
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
  }

  Repeater {
    model: root.tickCount > 1 ? root.tickCount : 0
    Rectangle {
      required property int index
      width: 2
      height: root.trackHeight + 4
      radius: 1
      color: root.tickColor
      anchors.verticalCenter: track.verticalCenter
      x: Math.max(0, Math.min(track.width - width, track.width * (index / (root.tickCount - 1)) - width / 2))
    }
  }

  Rectangle {
    width: root.knobSize
    height: root.knobSize
    radius: root.knobSize / 2
    color: root._hot ? Theme.foreground : root.knobColor
    anchors.verticalCenter: track.verticalCenter
    x: Math.max(0, Math.min(track.width - width, track.width * root.progress - width / 2))
    scale: root._hot ? 1.15 : 1.0

    Behavior on x {
      enabled: !root.dragging
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    function valueFromX(x) {
      var clamped = Math.max(0, Math.min(track.width, x))
      var raw = root.minimum + (clamped / track.width) * root.range
      if (root.integer) raw = Math.round(raw)
      return Math.max(root.minimum, Math.min(root.maximum, raw))
    }

    onPressed: function(mouse) {
      if (mouse.button !== Qt.LeftButton) return
      root.dragging = true
      var next = valueFromX(mouse.x)
      root.liveValue = next
      root.moved(next)
    }
    onClicked: function(mouse) { if (mouse.button === Qt.RightButton) root.rightClicked() }
    onPositionChanged: function(mouse) {
      if (!root.dragging) return
      var next = valueFromX(mouse.x)
      root.liveValue = next
      root.moved(next)
    }
    onReleased: function(mouse) {
      if (mouse.button !== Qt.LeftButton) return
      root.dragging = false
      root.released(root.liveValue)
      root.liveValue = root.value
    }
    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y > 0 ? root.step : -root.step
      var next = Math.max(root.minimum, Math.min(root.maximum, root.liveValue + delta))
      if (root.integer) next = Math.round(next)
      root.liveValue = next
      root.moved(next)
      root.released(next)
    }
  }
}
