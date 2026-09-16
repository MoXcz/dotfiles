import QtQuick
import Quickshell.Bluetooth
import qs.Commons
import qs.modules.bar.panels

// Adapter state from Quickshell.Bluetooth (BlueZ). Hidden when the machine
// has no adapter. Label is the connected device name, or a count when more
// than one is connected. Left click opens the devices panel.
BarButton {
  id: root

  // Read by WidgetSlot; binding visible directly would loop through the Loader.
  property bool shown: adapter !== null

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool on: adapter !== null && adapter.enabled
  // Use BlueZ's global live model. Adapter.devices may be populated before
  // this widget connects its change handler, which left already-connected
  // devices out until another device event happened.
  readonly property var devices: {
    var values = Bluetooth.devices ? Bluetooth.devices.values : []
    var list = values.filter(function(d) {
      return d.connected || d.paired || d.bonded || d.deviceName !== "" || d.name !== ""
    })
    list.sort(function(a, b) {
      return (b.connected - a.connected) || (b.paired - a.paired)
        || (b.bonded - a.bonded) || a.name.localeCompare(b.name)
    })
    return list
  }
  readonly property var connected: devices.filter(function(d) { return d.connected })

  function togglePanel() { panel.toggleFor(root) }

  icon: on ? "󰂯" : "󰂲"
  label: connected.length === 1 ? Util.truncate(connected[0].name, 24)
    : connected.length > 1 ? String(connected.length) : ""
  textColor: on ? Theme.foreground : Theme.muted
  panelActive: panel.opened

  onClicked: function(button) { if (button === Qt.LeftButton) togglePanel() }

  BluetoothPanel {
    id: panel
    adapter: root.adapter
    devices: root.devices
  }
}
