import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "center"

// One continuous status bar per screen. Transparent layout groups retain the
// left/center/right structure and provide anchors for the shared morphing
// panel; WidgetSlot turns configured ids into components.
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

  // Screen-local source geometry used by the launcher and command menu. Both
  // overlays follow the focused monitor, so map the clock from that bar into
  // its window rather than assuming the screen centre or a fixed width.
  function clockAnchor() {
    var win = barForFocus()
    if (!win) return Qt.rect(0, 0, Config.bar.dockHeight, Config.bar.dockHeight)
    var clock = win.findSlot("clock")
    if (!clock) return Qt.rect((win.width - Config.bar.dockHeight) / 2,
                               (Config.bar.height - Config.bar.dockHeight) / 2,
                               Config.bar.dockHeight, Config.bar.dockHeight)
    var p = clock.mapToItem(null, 0, 0)
    return Qt.rect(p.x, p.y, clock.width, clock.height)
  }

  function clockSlotForFocus() {
    var win = barForFocus()
    return win ? win.findSlot("clock") : null
  }

  function openCenter(mode) {
    mode = String(mode || "calendar")
    if (center.modes.indexOf(mode) < 0) return "unknown mode: " + mode
    if (center.opened) { center.switchTo(mode); return "ok" }
    var win = barForFocus()
    if (!win) return "no bar"
    var clock = win.findSlot("clock")
    if (!clock) return "no clock widget"
    center.open(mode, clock)
    return "ok on " + (win.screen ? win.screen.name : "?")
  }

  function closeCenter() {
    center.close()
  }

  function toggleCenter(mode) {
    mode = String(mode || "calendar")
    if (center.opened && center.mode === mode) { closeCenter(); return "ok" }
    return openCenter(mode)
  }

  CenterPanel {
    id: center
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

  // One shared morphing panel per screen, declared before the bars so the
  // compositor stacks its attached surface under them.
  Variants {
    model: Quickshell.screens
    DockPanel { required property var modelData; screen: modelData }
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

      // One continuous surface makes the bar the visual parent of every
      // widget, while the transparent inner docks retain their panel anchors.
      Rectangle {
        id: integratedBar
        anchors.fill: parent
        radius: 0
        color: Theme.surface
        // The popup card is below this window and overlaps the strip. An
        // outer border here would draw a seam straight through that junction.
        border.width: 0

        // The center dock is pinned to the screen middle; left and right hug
        // their contents from the edges. A dock with nothing in it hides.
        Dock {
          id: leftDock
          integrated: true
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
              integrated: true
              required property string modelData
              required property int index
              align: modelData === "clock" ? "center"
                   : index > Config.bar.center.indexOf("clock") ? "left" : "right"
              WidgetSlot { widgetId: bubble.modelData; host: root; window: win }
            }
          }
        }

        // One stable status cluster. Nothing is hidden behind hover: keeping
        // every configured item present makes direct panel-to-panel clicks
        // predictable and gives the right side one continuous rhythm.
        Dock {
          id: rightDock
          integrated: true
          align: "right"
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: Config.bar.right.length > 0 || Config.bar.rightMore.length > 0
          Repeater {
            model: Config.bar.rightMore
            WidgetSlot { required property string modelData; widgetId: modelData; host: root; window: win }
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
