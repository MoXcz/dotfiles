import QtQuick
import qs.Commons
import qs.modules.bar.panels

// CPU, memory and, GPU readout; goes warning-colored when the CPU runs hot.
// Left click opens the system panel with the full breakdown.
BarButton {
  id: root

  readonly property bool hot: stats.cpuTemp > 85 || stats.gpuTemp > 85

  function reading(usage, temp) {
    return Math.round(usage) + "%" + (temp >= 0 ? " " + temp + "°" : "")
  }

  function togglePanel() { panel.toggleFor(root) }

  icon: "󰻠"
  label: reading(stats.cpu, stats.cpuTemp)
         + "  󰍛 " + Math.round(stats.memPercent) + "%"
         + (stats.gpuAvailable ? "  󰢮 " + reading(stats.gpuUtil, stats.gpuTemp) : "")
  textColor: hot ? Theme.warning : Theme.foreground

  onClicked: function(button) { if (button === Qt.LeftButton) togglePanel() }

  SystemStats { id: stats }
  SystemPanel { id: panel; stats: stats }
}
