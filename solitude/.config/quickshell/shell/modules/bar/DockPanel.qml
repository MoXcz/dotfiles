import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// One persistent surface per screen hosts every bar panel. Switching widgets
// moves and reshapes this card while old and new contents crossfade, so menus
// read as states of the bar rather than unrelated popup windows.
PanelWindow {
  id: root

  property var current: null
  property var outgoing: null
  property var dock: null
  property var sourceCell: null
  property bool expanded: false
  // Suppress interpolation while placing a closed card at a newly clicked
  // source. Without this, its old/default x is animated and the card appears
  // to fly in from a screen edge before it can grow from the widget.
  property bool geometryReady: false
  property rect origin: Qt.rect(0, 0, 0, 0)
  readonly property bool opened: current !== null
  readonly property bool atBottom: Config.bar.position === "bottom"
  readonly property int animationMs: Config.dockPanel.animationMs

  function dockOf(item) {
    var it = item
    while (it && !it.isDock) it = it.parent
    return it || null
  }

  function clearOutgoing() {
    if (!outgoing) return
    outgoing.visible = false
    outgoing.parent = null
    outgoing = null
  }

  function show(panel, cell) {
    var win = cell.QsWindow.window
    if (!win || win.screen !== root.screen) return
    var nextDock = dockOf(cell)
    if (!nextDock) return

    var wasOpen = opened && expanded
    hideTimer.stop()
    clearOutgoing()

    if (!wasOpen) {
      geometryReady = false
      expanded = false
    }

    if (current && current !== panel) {
      outgoing = current
      outgoing.panelOpen = false
      outgoing.parent = outgoingSlot
      outgoing.anchors.fill = outgoingSlot
      outgoingSlot.opacity = 1
    }

    if (dock && dock !== nextDock) dock.flat = false
    dock = nextDock
    dock.flat = true
    sourceCell = cell
    var p = cell.mapToItem(null, 0, 0)
    origin = Qt.rect(p.x, p.y, cell.width, cell.height)

    panel.parent = incomingSlot
    panel.anchors.fill = incomingSlot
    panel.visible = true
    panel.panelOpen = true
    current = panel
    focusTimer.restart()
    if (wasOpen) {
      expanded = true
    } else {
      // Let the disabled Behaviors commit origin first, then grow around the
      // clicked item's centre on the next frame.
      Qt.callLater(function() {
        if (root.current !== panel) return
        root.geometryReady = true
        root.expanded = true
      })
    }

    incomingSlot.opacity = 0
    if (wasOpen) incomingSlot.opacity = 1
    else revealTimer.restart()
    if (outgoing) outgoingFade.restart()
  }

  function release() {
    if (dock) dock.flat = false
    dock = null
    sourceCell = null
  }

  function close() {
    if (!opened) return
    expanded = false
    current.panelOpen = false
    incomingSlot.opacity = 0
    revealTimer.stop()
    if (dock) dock.flat = false
    hideTimer.restart()
  }

  Timer {
    id: focusTimer
    interval: 0
    onTriggered: keys.forceActiveFocus()
  }

  Timer {
    id: revealTimer
    interval: Math.round(root.animationMs * 0.38)
    onTriggered: if (root.current && root.expanded) incomingSlot.opacity = 1
  }

  Timer {
    id: hideTimer
    interval: root.animationMs + 30
    onTriggered: {
      if (root.current) {
        root.current.visible = false
        root.current.parent = null
      }
      root.current = null
      root.clearOutgoing()
      root.release()
      root.geometryReady = false
    }
  }

  NumberAnimation {
    id: outgoingFade
    target: outgoingSlot
    property: "opacity"
    from: 1
    to: 0
    duration: Config.dockPanel.contentFadeMs
    easing.type: Easing.OutCubic
    onFinished: root.clearOutgoing()
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
  // Every hosted panel has keyboard actions. Exclusive keyboard focus keeps
  // j/k, arrows, Enter and text input reliable; the input mask still omits
  // the bar strip, so its widgets remain directly pointer-clickable.
  WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  mask: opened ? outsideBar : none

  Region { id: none }
  Region {
    id: outsideBar
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
      if (root.current && root.current.handleKey && root.current.handleKey(event)) {
        event.accepted = true
        return
      }
      if (event.key === Qt.Key_Escape || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
        root.close()
        event.accepted = true
      }
    }

    Card {
      id: card
      readonly property real sourceWidth: Math.max(1, root.origin.width)
      readonly property real sourceHeight: Math.max(1, root.origin.height)
      readonly property real panelWidth: root.current ? Math.max(root.current.panelWidth, sourceWidth) : sourceWidth
      readonly property real panelHeight: sourceHeight + body.implicitHeight + Theme.spaceLg + Theme.space
      readonly property real desiredX: root.origin.x + (sourceWidth - panelWidth) / 2
      readonly property real openX: Util.clamp(desiredX, Theme.space, root.width - panelWidth - Theme.space)
      readonly property real openY: root.atBottom ? root.origin.y + sourceHeight - panelHeight : root.origin.y

      x: root.expanded ? openX : root.origin.x
      y: root.expanded ? openY : root.origin.y
      width: root.expanded ? panelWidth : sourceWidth
      height: root.expanded ? panelHeight : sourceHeight
      radius: root.expanded ? Theme.bubbleRadius : sourceHeight / 2
      clip: true
      visible: root.expanded || hideTimer.running

      Behavior on x { enabled: root.geometryReady; NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: root.geometryReady; NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic } }
      Behavior on width { enabled: root.geometryReady; NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic } }
      Behavior on height { enabled: root.geometryReady; NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic } }
      Behavior on radius { enabled: root.geometryReady; NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic } }

      Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.atBottom ? undefined : parent.top
        anchors.bottom: root.atBottom ? parent.bottom : undefined
        anchors.topMargin: root.atBottom ? 0 : card.sourceHeight + Theme.space
        anchors.bottomMargin: root.atBottom ? card.sourceHeight + Theme.space : 0
        anchors.leftMargin: Theme.spaceLg
        anchors.rightMargin: Theme.spaceLg
        implicitHeight: root.current ? root.current.implicitHeight : 0

        Behavior on implicitHeight {
          enabled: root.geometryReady
          NumberAnimation { duration: root.animationMs; easing.type: Easing.OutCubic }
        }

        Item {
          id: outgoingSlot
          anchors.fill: parent
          opacity: 0
        }

        Item {
          id: incomingSlot
          anchors.fill: parent
          opacity: 0
          Behavior on opacity {
            NumberAnimation {
              duration: root.expanded ? Config.dockPanel.contentFadeMs : 80
              easing.type: root.expanded ? Easing.OutCubic : Easing.InCubic
            }
          }
        }
      }
    }
  }
}
