import QtQuick
import qs.Commons
import qs.modules.bar.widgets
import qs.modules.displays

// Bar cell for the displays panel (hyprmoncfg). Glyph shows one or several
// monitors, a small accent check marks a live daemon connection, and the
// label is the active profile (or the monitor count when there is none).
// The panel owns the daemon socket and all state; this cell only reflects
// it and hosts the popup.
BarButton {
  id: root

  // Touching the singleton here brings the preview guard up with the first
  // widget, so a Keep/Revert dialog exists even when the popup is closed.
  readonly property bool guardConnected: PreviewGuard.connected
  readonly property bool backendConnected: panel.backendConnected
  readonly property int monitorCount: panel.monitorCount
  readonly property string activeProfile: panel.activeProfile

  icon: monitorCount > 1 ? "󰍺" : "󰍹"
  label: activeProfile !== "" ? Util.truncate(activeProfile, 18) : (monitorCount > 1 ? String(monitorCount) : "")
  iconColor: panel.barIconDimmed ? Theme.muted : Theme.foreground
  panelActive: panel.opened

  function togglePanel() { panel.toggle() }

  onClicked: function(button) { if (button === Qt.LeftButton) togglePanel() }

  // Connected marker tucked into the glyph's corner.
  Text {
    visible: root.backendConnected
    x: root.paddingX + Theme.fontIcon * 0.55
    y: root.height / 2 + Theme.fontIcon * 0.05
    text: "󰄬"
    color: Theme.accent
    font.family: Theme.fontFamily
    font.pixelSize: Math.max(7, Math.round(Theme.fontIcon * 0.45))
    font.bold: true
  }

  DisplaysPanel { id: panel; anchorItem: root }
}
