import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "center"

// One status bar per screen: three floating docks (left, center, right)
// over a transparent strip. Sections are filled from the widget id lists in
// Config.bar; WidgetSlot turns each id into a component.
Item {
  id: root

  property bool hidden: false
  readonly property bool atBottom: Config.bar.position === "bottom"
  // Unknown widget ids already reported, so each one is logged only once.
  property var warnedIds: ({})

  // Toggle a widget's popup panel by widget id, on the bar of the monitor
  // that has focus. Taking the first instance instead put every panel on
  // whichever screen Quickshell happened to enumerate first.
  function barForFocus() {
    var instances = bars.instances
    if (instances.length === 0) return null
    var monitor = Hyprland.focusedMonitor
    if (monitor) {
      for (var i = 0; i < instances.length; i++) {
        var screen = instances[i].screen
        if (screen && screen.name === monitor.name) return instances[i]
      }
    }
    return instances[0]
  }

  // ---------------------------------------------------------------- center panel
  // While the panel is up the clock's bubble widens to the panel's width so
  // the other center bubbles slide aside, and the panel card morphs out of
  // the bubble's rectangle.
  property string centerMode: ""
  property int centerWidth: 0
  property var centerWin: null

  function centerWidthFor(mode) {
    return mode === "calendar" ? Config.center.calendarWidth : Config.center.carouselWidth
  }

  function centerDocks(win) {
    var out = []
    var kids = win.centerRow.children
    for (var i = 0; i < kids.length; i++) if (typeof kids[i].modelData === "string") out.push(kids[i])
    return out
  }

  // Screen-space rectangle the clock's bubble will occupy once widened to
  // `width`; the panel card animates into it.
  function centerGeometry(width) {
    var win = centerWin
    if (!win) return Qt.rect(0, 0, width, 0)
    var docks = centerDocks(win)
    var total = 0, before = -1
    for (var i = 0; i < docks.length; i++) {
      var w = docks[i].modelData === "clock" ? width : docks[i].implicitWidth
      if (docks[i].modelData === "clock") before = total
      total += w + (i > 0 ? win.centerRow.spacing : 0)
    }
    if (before < 0) before = 0
    var x = Config.bar.marginX + Math.round((win.width - total) / 2) + before
    return Qt.rect(x, Config.bar.marginY, width, Config.bar.dockHeight)
  }

  function setCenterMode(mode) {
    centerMode = mode
    centerWidth = centerWidthFor(mode)
  }

  function openCenter(mode) {
    mode = String(mode || "calendar")
    if (center.modes.indexOf(mode) < 0) return "unknown mode: " + mode
    if (center.opened) { center.switchTo(mode); return "ok" }
    var win = barForFocus()
    if (!win) return "no bar"
    var docks = centerDocks(win)
    var clock = null
    for (var i = 0; i < docks.length; i++) if (docks[i].modelData === "clock") clock = docks[i]
    if (!clock) return "no clock bubble"
    Bus.dockPanelsCloseAll()
    centerWin = win
    var p = clock.mapToItem(null, 0, 0)
    var pill = Qt.rect(Config.bar.marginX + p.x, p.y, clock.width, clock.height)
    setCenterMode(mode)
    center.open(mode, win.screen, pill)
    return "ok on " + (win.screen ? win.screen.name : "?")
  }

  function closeCenter() {
    center.close()
    centerMode = ""
  }

  function toggleCenter(mode) {
    mode = String(mode || "calendar")
    if (center.opened && center.mode === mode) { closeCenter(); return "ok" }
    return openCenter(mode)
  }

  CenterPanel {
    id: center
    host: root
    // Closing from inside the panel (outside click, Escape, a pick) has to
    // shrink the clock's slot too, in step with the card.
    onExpandedChanged: if (!expanded) root.centerMode = ""
  }

  Connections {
    target: Bus
    function onCenterRequested(mode) { root.toggleCenter(mode) }
  }

  function openPanel(name) {
    var win = barForFocus()
    if (!win) return "no bar"
    var slot = win.findSlot(String(name || ""))
    if (!slot) return "unknown widget: " + name
    if (!slot.item || typeof slot.item.togglePanel !== "function") return "no panel: " + name
    slot.item.togglePanel()
    // Naming the screen makes it obvious which bar answered when a panel
    // opens somewhere unexpected.
    return "ok on " + (win.screen ? win.screen.name : "?")
  }

  // One per screen, declared before the bars so it maps first and the
  // compositor stacks it under them.
  Variants {
    model: Quickshell.screens
    DockPanel { required property var modelData; screen: modelData; host: root }
  }

  Variants {
    id: bars
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData

      function findSlot(id) {
        var docks = [leftDock, rightDock]
        for (var c = 0; c < centerRow.children.length; c++) docks.push(centerRow.children[c])
        for (var s = 0; s < docks.length; s++) {
          var kids = docks[s].content
          if (!kids) continue
          for (var i = 0; i < kids.length; i++) {
            if (kids[i].widgetId === id) return kids[i]
            // The right dock's folded row is one level down.
            var inner = kids[i].children
            for (var j = 0; inner && j < inner.length; j++) {
              var deep = inner[j].children
              for (var k = 0; deep && k < deep.length; k++) if (deep[k].widgetId === id) return deep[k]
            }
          }
        }
        return null
      }

      readonly property alias centerRow: centerRow

      screen: modelData

      // hide bar on active workspace that has a fullscreen
      readonly property var hyprMonitor: Hyprland.monitorFor(screen)
      readonly property bool fullscreen: hyprMonitor && hyprMonitor.activeWorkspace
                                       && hyprMonitor.activeWorkspace.hasFullscreen
      visible: !root.hidden && !fullscreen
      color: "transparent"
      implicitHeight: Config.bar.height
      exclusiveZone: root.hidden || fullscreen ? 0 : Config.bar.height
      WlrLayershell.namespace: "shell-bar"
      // Overlay, not Top: the dock-panel card lives on Top and must stay
      // under the docks, which are its header.
      WlrLayershell.layer: WlrLayer.Overlay
      anchors { left: true; right: true; top: !root.atBottom; bottom: root.atBottom }
      margins { left: Config.bar.marginX; right: Config.bar.marginX }

      Item {
        anchors.fill: parent
        anchors.topMargin: root.atBottom ? 0 : Config.bar.marginY
        anchors.bottomMargin: root.atBottom ? Config.bar.marginY : 0

        // The center dock is pinned to the screen middle; left and right hug
        // their contents from the edges. A dock with nothing in it hides.
        Dock {
          id: leftDock
          align: "left"
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          visible: Config.bar.left.length > 0
          Repeater {
            model: Config.bar.left
            WidgetSlot { required property string modelData; widgetId: modelData; host: root; window: win }
          }
        }

        // Center widgets each float in their own bubble.
        Row {
          id: centerRow
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          spacing: Theme.space
          Repeater {
            model: Config.bar.center
            Dock {
              id: bubble
              required property string modelData
              required property int index
              // A bubble's card grows away from the clock so it never runs
              // under the clock pill, which is drawn above it.
              align: modelData === "clock" ? "center"
                   : index > Config.bar.center.indexOf("clock") ? "left" : "right"
              readonly property bool expanded: modelData === "clock" && root.centerMode !== ""
              width: expanded ? root.centerWidth : implicitWidth
              // The panel card covers this bubble; fade it so nothing peeks
              // out past the card's rounded corners.
              opacity: expanded ? 0 : 1
              Behavior on width { NumberAnimation { duration: Config.center.animationMs; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
              // Hide at once when the card takes over; on the way back wait
              // until the card has shrunk into the pill, or both show at once.
              Behavior on opacity {
                SequentialAnimation {
                  PauseAnimation { duration: bubble.expanded ? 0 : Config.center.animationMs * 0.75 }
                  NumberAnimation { duration: bubble.expanded ? 60 : 120 }
                }
              }
              WidgetSlot { widgetId: bubble.modelData; host: root; window: win }
            }
          }
        }

        // The right dock shows its main widgets and unfolds the rest to the
        // left while hovered, or while one of them has its panel up.
        Dock {
          id: rightDock
          align: "right"
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: Config.bar.right.length > 0 || Config.bar.rightMore.length > 0
          // A panel opening unfolds the whole dock, like a hover would, and
          // after it closes the dock stays unfolded a moment before folding.
          readonly property bool unfolded: hovered || flat || collapse.running
          onHoveredChanged: if (!hovered) collapse.restart(); else collapse.stop()
          onFlatChanged: if (!flat) { collapse.interval = Config.dockPanel.linger; collapse.restart() }
                         else collapse.stop()

          Timer {
            id: collapse
            interval: Config.dockPanel.collapseDelayMs
            onTriggered: interval = Config.dockPanel.collapseDelayMs
          }

          Item {
            id: more
            height: parent.height
            width: rightDock.unfolded ? moreRow.implicitWidth + rightDock.spacing : 0
            clip: true
            opacity: rightDock.unfolded ? 1 : 0
            Behavior on width { NumberAnimation { duration: Config.dockPanel.unfoldMs; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Config.dockPanel.unfoldMs } }
            Row {
              id: moreRow
              anchors.right: parent.right
              height: parent.height
              spacing: rightDock.spacing
              Repeater {
                model: Config.bar.rightMore
                WidgetSlot { required property string modelData; widgetId: modelData; host: root; window: win }
              }
            }
          }
          Repeater {
            model: Config.bar.right
            WidgetSlot { required property string modelData; widgetId: modelData; host: root; window: win }
          }
        }
      }
    }
  }
}
