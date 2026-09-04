import QtQuick
import Quickshell.Services.UPower
import qs.Commons
import qs.modules.bar.panels

// Battery level from UPower's aggregate display device. Hidden entirely on
// machines without a battery. Left click opens the details panel.
BarButton {
  id: root

  // Read by WidgetSlot; binding visible directly would loop through the Loader.
  property bool shown: present

  readonly property var device: UPower.displayDevice
  readonly property bool present: device !== null && device.ready
    && device.type === UPowerDeviceType.Battery && device.isPresent
  readonly property int percent: present ? Math.round(device.percentage * 100) : 0
  readonly property bool charging: present
    && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
  readonly property bool full: present && device.state === UPowerDeviceState.FullyCharged
  readonly property bool low: present && !charging && !full && percent < 15

  readonly property var glyphs: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
  readonly property var chargingGlyphs: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]

  function togglePanel() { panel.toggleFor(root) }

  icon: (charging || full ? chargingGlyphs : glyphs)[Util.clamp(Math.floor((percent - 1) / 10), 0, 9)]
  label: percent + "%"
  textColor: low ? Theme.urgent : Theme.foreground

  onClicked: function(button) { if (button === Qt.LeftButton) togglePanel() }

  BatteryPanel { id: panel; device: root.device }
}
