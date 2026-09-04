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
  // Known devices, connected first, then paired, then by name. Rebuilt on
  // membership and (dis)connect / pair changes only.
  property var devices: []
  readonly property var connected: devices.filter(function(d) { return d.connected })

  function refresh() {
    var list = adapter ? adapter.devices.values.filter(function(d) {
      return d.paired || d.connected || d.deviceName !== ""
    }) : []
    list.sort(function(a, b) {
      return (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)
    })
    devices = list
  }

  function togglePanel() { panel.toggleFor(root) }

  icon: on ? "󰂯" : "󰂲"
  label: connected.length === 1 ? Util.truncate(connected[0].name, 24)
    : connected.length > 1 ? String(connected.length) : ""
  textColor: on ? Theme.foreground : Theme.muted

  onAdapterChanged: refresh()
  Connections {
    target: root.adapter ? root.adapter.devices : null
    function onValuesChanged() { root.refresh() }
  }
  // Per-device watch so a (dis)connect or pairing re-sorts the list.
  Instantiator {
    model: root.adapter ? root.adapter.devices : null
    QtObject {
      required property var modelData
      readonly property bool connected: modelData.connected
      readonly property bool paired: modelData.paired
      readonly property string deviceName: modelData.deviceName
      onConnectedChanged: root.refresh()
      onPairedChanged: root.refresh()
      onDeviceNameChanged: root.refresh()
    }
  }

  onClicked: function(button) { if (button === Qt.LeftButton) togglePanel() }

  BluetoothPanel {
    id: panel
    adapter: root.adapter
    devices: root.devices
  }
}
