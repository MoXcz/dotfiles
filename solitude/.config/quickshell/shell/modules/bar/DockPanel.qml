import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Card that a dock morphs into when one of its widgets opens a panel. One
// instance per screen: the widget's BarPopup content is reparented into
// `slot`, and the card starts at the dock's rectangle and grows downward.
//
// The window is always mapped, full-screen and transparent, on the top
// layer while the bar sits on the overlay layer, so it stacks underneath:
// the dock stays in the bar, on top of the card, live and clickable as the
// card's header. While closed the input mask is empty, so clicks pass
// through.
PanelWindow {
  id: root

  required property Item host              // Bar root
  property var current: null               // BarPopup being shown
  property var dock: null                  // Dock the card grew from
  property bool expanded: false
  // Dock rectangle at open time, screen coordinates. Its width is only a
  // fallback: the card's minimum width follows the live dock width, so a
  // dock that unfolds while its panel is up moves the card with it.
  property rect origin: Qt.rect(0, 0, 0, 0)
  readonly property real dockWidth: dock ? dock.width : origin.width
  readonly property real originRight: origin.x + origin.width
  readonly property bool opened: current !== null
  readonly property bool atBottom: Config.bar.position === "bottom"
  readonly property int animationMs: Config.dockPanel.animationMs

  function dockOf(item) {
    var it = item
    while (it && !it.isDock) it = it.parent
    return it || null
  }

  function show(panel, cell) {
    var win = cell.QsWindow.window
    if (!win || win.screen !== root.screen) return
    var d = dockOf(cell)
    if (!d) return
    host.closeCenter()
    hideTimer.stop()
    if (current && current !== panel) current.visible = false
    var p = d.mapToItem(null, 0, 0)
    origin = Qt.rect(Config.bar.marginX + p.x, p.y, d.width, d.height)
    if (dock && dock !== d) release()
    dock = d
    dock.flat = true
    panel.parent = slot
    panel.anchors.fill = slot
    panel.visible = true
    current = panel
    keys.forceActiveFocus()
    expanded = true
  }

  function release() {
    if (!dock) return
    dock.flat = false
    dock = null
  }

  function close() {
    if (!opened) return
    expanded = false
    if (current) current.visible = false
    // The dock folds now, animated, in step with the card shrinking.
    if (dock) dock.flat = false
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: root.animationMs
    onTriggered: { root.release(); root.current = null }
  }

  Connections {
    target: Bus
    function onDockPanelRequested(panel, cell) { root.show(panel, cell) }
    function onDockPanelDismissed(panel) { if (panel === root.current) root.close() }
    function onDockPanelsCloseAll() { root.close() }
  }

  visible: true
  color: "transparent"
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "shell-dock-panel"
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  // Input region: nothing while closed, and everything except the bar
  // strip while open — an exclusive-keyboard layer gets every pointer
  // event landing on its input region, so leaving the strip out keeps
  // clicks on the docks (swapping panels) with the bar.
  mask: opened ? belowBar : none
  Region { id: none }
  Region {
    id: belowBar
    x: 0
    y: root.atBottom ? 0 : Config.bar.height
    width: root.width
    height: root.height - Config.bar.height
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true
    Keys.onPressed: function(event) {
      if (root.current && root.current.handleKey && root.current.handleKey(event)) { event.accepted = true; return }
      if (event.key === Qt.Key_Escape || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
        root.close()
        event.accepted = true
      }
    }

    Card {
      id: card
      readonly property int panelWidth: root.current ? Math.max(root.current.panelWidth, root.dockWidth) : root.dockWidth
      readonly property real fullHeight: root.origin.height + body.implicitHeight + Theme.spaceLg + Theme.space
      // One animated progress drives the morph, so the card's geometry
      // tracks the dock instantly (a fold opening, a panel swapping) and
      // only the growth itself eases.
      property real grow: root.expanded ? 1 : 0
      Behavior on grow {
        NumberAnimation {
          duration: root.animationMs
          easing.type: root.expanded ? Easing.OutBack : Easing.InCubic
          easing.overshoot: 1.08
        }
      }

      width: root.dockWidth + (panelWidth - root.dockWidth) * grow
      height: root.origin.height + (fullHeight - root.origin.height) * grow
      // Grows out of the dock: right-pinned docks keep their right edge,
      // left-pinned their left, bubbles stay centered.
      x: !root.dock ? root.origin.x
       : root.dock.align === "right" ? root.originRight - width
       : root.dock.align === "left" ? root.origin.x
       : root.origin.x + (root.origin.width - width) / 2
      y: root.origin.y
      radius: root.origin.height / 2 + (Theme.bubbleRadius - root.origin.height / 2) * Math.min(1, grow)
      clip: true
      visible: root.expanded || grow > 0

      // Content sits below the dock's strip, fades in once the card has
      // most of its size, and drops first on close.
      Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.origin.height + Theme.space
        anchors.leftMargin: Theme.spaceLg
        anchors.rightMargin: Theme.spaceLg
        implicitHeight: slot.implicitHeight
        opacity: root.expanded ? 1 : 0
        Behavior on opacity {
          SequentialAnimation {
            PauseAnimation { duration: root.expanded ? root.animationMs * 0.3 : 0 }
            NumberAnimation { duration: root.expanded ? 100 : 60 }
          }
        }

        Item {
          id: slot
          width: parent.width
          height: root.current ? root.current.implicitHeight : 0
          implicitHeight: height
        }
      }
    }
  }
}
