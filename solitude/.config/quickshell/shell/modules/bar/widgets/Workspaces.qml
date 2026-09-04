import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Commons

// Workspace switcher for the monitor this bar sits on: one circle per
// workspace, showing its number or the icon from Config.bar.workspaceIcons.
// The focused one stretches into a wide pill and fills with the accent;
// occupied ones carry a foreground ring, empty ones sit muted.
Item {
  id: root

  property var screen: null

  // Match by name: monitorFor() can register a monitor while evaluating,
  // which changes the list this binding reads and loops.
  readonly property var monitor: {
    if (!screen) return null
    var all = Hyprland.monitors.values
    for (var i = 0; i < all.length; i++) {
      if (all[i].name === screen.name) return all[i]
    }
    return null
  }
  readonly property var active: monitor ? monitor.activeWorkspace : null

  // Always show the configured slot count, extended to the highest id that
  // exists on this monitor.
  readonly property var ids: {
    var all = Hyprland.workspaces.values
    var max = Config.bar.workspaceCount
    for (var i = 0; i < all.length; i++) {
      if (all[i].id > max && all[i].monitor === monitor) max = all[i].id
    }
    var out = []
    for (var id = 1; id <= max; id++) out.push(id)
    return out
  }

  function workspaceById(id) {
    var all = Hyprland.workspaces.values
    for (var i = 0; i < all.length; i++) {
      if (all[i].id === id) return all[i]
    }
    return null
  }

  // Resolve a Config.bar.workspaceIcons entry to an image URL, or "" when it
  // is a glyph (or nothing is configured), in which case text is drawn.
  function iconUrl(id) {
    var entry = Config.bar.workspaceIcons[id]
    if (entry === undefined || entry === null) return ""
    var candidates = Array.isArray(entry) ? entry : [entry]
    for (var i = 0; i < candidates.length; i++) {
      var name = String(candidates[i])
      if (name.charAt(0) === "/") return Util.fileUrl(name)
      var path = Quickshell.iconPath(name, true)
      if (path) return path
    }
    return ""
  }

  function glyph(id) {
    var entry = Config.bar.workspaceIcons[id]
    if (entry === undefined || entry === null) return String(id)
    var text = Array.isArray(entry) ? "" : String(entry)
    // A desktop icon name that did not resolve still shows the number.
    return text.length > 0 && text.length <= 2 ? text : String(id)
  }

  function focus(id) {
    Hyprland.dispatch(Hyprland.usingLua ? 'hl.dsp.focus({ workspace = "' + id + '" })' : "workspace " + id)
  }

  function step(delta) {
    var current = active ? active.id : 1
    var next = delta > 0 ? current - 1 : current + 1
    if (next >= 1 && next <= ids.length) focus(next)
  }

  readonly property int size: Config.bar.workspaceSize
  readonly property int focusedWidth: Config.bar.workspaceFocusedWidth

  implicitWidth: row.implicitWidth

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.spaceSm

    Repeater {
      model: root.ids

      // The cell itself animates its width, so neighbours slide over as the
      // focused pill stretches instead of jumping.
      Rectangle {
        id: cell
        required property int modelData
        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool focused: root.active !== null && root.active.id === modelData
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool urgent: workspace !== null && workspace.urgent
        readonly property string image: root.iconUrl(modelData)

        width: focused ? root.focusedWidth : root.size
        height: root.size
        radius: height / 2
        color: focused ? Theme.accent
             : urgent ? Util.alpha(Theme.urgent, 0.25)
             : area.containsMouse ? Theme.hover : "transparent"
        border.width: focused ? 0 : Theme.borderWidth
        border.color: urgent ? Theme.urgent : occupied ? Theme.foreground : Theme.border

        // Overshoot makes the stretch read as a bubble rather than a resize.
        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        IconImage {
          anchors.centerIn: parent
          visible: cell.image.length > 0
          source: cell.image
          implicitSize: Math.round(root.size * 0.62)
          // Empty workspaces show their icon dimmed, like their number.
          opacity: cell.focused || cell.occupied || cell.urgent ? 1 : 0.45
          Behavior on opacity { NumberAnimation { duration: 160 } }
        }

        Text {
          anchors.fill: parent
          visible: cell.image.length === 0
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: root.glyph(cell.modelData)
          color: cell.focused ? Theme.background
               : cell.urgent ? Theme.urgent
               : cell.occupied ? Theme.foreground : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontCaption
          font.weight: cell.focused ? Font.Bold : Font.Normal
          Behavior on color { ColorAnimation { duration: 160 } }
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.focus(cell.modelData)
          onWheel: function(event) { root.step(event.angleDelta.y) }
        }
      }
    }
  }
}
