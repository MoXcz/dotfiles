import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "../../menu/Routes.js" as Routes

// The clock's panel: calendar, theme switcher or background switcher,
// whichever was asked for. The card starts as the clock pill itself and morphs downwards into the panel
// while the bar widens the pill's slot so its neighbours slide aside; the
// bar drives that through `host` (Bar.qml), which also supplies geometry.
//
// Full-screen transparent layer so a click anywhere else closes it and the
// keyboard stays with the panel while it is up.
PanelWindow {
  id: root

  required property Item host          // Bar root
  property string mode: ""             // "" closed | calendar | theme | background
  property bool expanded: false        // card morphed out of the pill
  property rect origin: Qt.rect(0, 0, 0, 0)   // clock pill, screen coordinates
  readonly property bool atBottom: Config.bar.position === "bottom"
  readonly property int animationMs: Config.center.animationMs
  readonly property var modes: ["calendar", "theme", "background"]

  readonly property int targetWidth: mode === "calendar" ? Config.center.calendarWidth : Config.center.carouselWidth
  readonly property bool opened: mode !== ""

  function open(which, screenTarget, pill) {
    hideTimer.stop()
    root.screen = screenTarget
    origin = pill
    mode = which
    visible = true
    keys.forceActiveFocus()
    if (backingWindowVisible) expanded = true
  }

  function switchTo(which) {
    if (which === mode || modes.indexOf(which) < 0) return
    mode = which
    host.setCenterMode(which)
    // Theme and background share the carousel component, so the Loader
    // keeps the item; point it at the other generator by hand.
    if (content.item && content.item.load) { content.item.route = Routes.picker(mode); content.item.load() }
  }

  function close() {
    if (!opened) return
    expanded = false
    hideTimer.restart()
  }

  onBackingWindowVisibleChanged: if (backingWindowVisible && opened && !hideTimer.running) expanded = true

  Timer {
    id: hideTimer
    interval: root.animationMs + 20
    onTriggered: { root.mode = ""; root.visible = false }
  }

  visible: false
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "shell-center"
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true
    Keys.onPressed: function(event) {
      event.accepted = true
      if (event.key === Qt.Key_Escape || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { root.close(); return }
      if (content.item && content.item.handleKey && content.item.handleKey(event)) return
      event.accepted = false
    }

    Card {
      id: card
      // Geometry in screen coordinates: the pill when collapsed, the panel
      // slot the bar computed when expanded. One animated progress drives
      // the morph so nothing lags behind anything else.
      readonly property rect target: root.host.centerGeometry(root.targetWidth)
      readonly property real fullHeight: body.implicitHeight + Theme.spaceLg * 2 + Theme.space
      property real grow: root.expanded ? 1 : 0
      Behavior on grow {
        NumberAnimation {
          duration: root.animationMs
          easing.type: root.expanded ? Easing.OutBack : Easing.InCubic
          easing.overshoot: 1.08
        }
      }
      x: root.origin.x + (target.x - root.origin.x) * Math.min(1, grow)
      y: root.origin.y
      width: root.origin.width + (target.width - root.origin.width) * grow
      height: root.origin.height + (fullHeight - root.origin.height) * grow
      radius: root.origin.height / 2 + (Theme.bubbleRadius - root.origin.height / 2) * Math.min(1, grow)
      clip: true
      // Gone the moment it has shrunk back into the pill; the pill itself
      // fades back in underneath (see Bar.qml).
      visible: root.expanded || grow > 0

      // Content fades in once the card has most of its size, and drops out
      // first on close so the pill never shows half a calendar.
      Item {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.spaceLg
        implicitHeight: content.item ? content.item.implicitHeight : 0
        opacity: root.expanded ? 1 : 0
        Behavior on opacity {
          SequentialAnimation {
            PauseAnimation { duration: root.expanded ? root.animationMs * 0.45 : 0 }
            NumberAnimation { duration: root.expanded ? 160 : 80 }
          }
        }

        Loader {
          id: content
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          sourceComponent: root.mode === "calendar" ? calendarComp
                         : root.mode === "theme" || root.mode === "background" ? carouselComp : null
          onLoaded: {
            if (root.mode === "calendar") item.reset()
            else { item.route = Routes.picker(root.mode); item.load() }
          }
        }
      }
    }
  }

  Component { id: calendarComp; CalendarView {} }
  Component {
    id: carouselComp
    Carousel { onActivated: root.close() }
  }
}
