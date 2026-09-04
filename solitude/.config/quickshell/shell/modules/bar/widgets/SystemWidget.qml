import QtQuick
import qs.Commons
import qs.modules.bar.panels

// CPU (usage and temperature) and memory readout; goes warning-colored when
// the CPU runs hot.
// Left click opens the system panel with the full breakdown.
BarButton {
  id: root

  readonly property bool hot: stats.cpuTemp > 85

  function togglePanel() { panel.toggleFor(root) }

  icon: "󰻠"
  label: Math.round(stats.cpu) + "%" + (stats.cpuTemp >= 0 ? " " + stats.cpuTemp + "°" : "")
         + "  󰍛 " + Math.round(stats.memPercent) + "%"
  textColor: hot ? Theme.warning : Theme.foreground

  onClicked: function(button) { if (button === Qt.LeftButton) togglePanel() }

  SystemStats { id: stats }
  SystemPanel { id: panel; stats: stats }
}
