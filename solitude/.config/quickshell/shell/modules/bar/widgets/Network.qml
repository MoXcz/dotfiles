import QtQuick
import Quickshell.Networking
import qs.Commons
import qs.modules.bar.panels

// Connection state from Quickshell.Networking (NetworkManager). Wired wins
// when both are up. Left click opens the Wi-Fi panel. `compact` drops the
// network name so the widget fits a single bubble.
BarButton {
  id: root

  property bool compact: false

  readonly property var wifi: firstDevice(DeviceType.Wifi)
  readonly property var wired: firstDevice(DeviceType.Wired)
  // Visible Wi-Fi networks, connected and known ones first, then by signal.
  // Rebuilt on membership or connection changes only, so rows do not jump
  // around while signal levels drift.
  property var networks: []
  readonly property var active: networks.length > 0 && networks[0].connected ? networks[0] : null
  readonly property bool wiredUp: wired !== null && wired.connected
  readonly property string kind: wiredUp ? "ethernet" : active ? "wifi" : "none"
  readonly property real strength: active ? active.signalStrength : 0
  readonly property var glyphs: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]

  function firstDevice(type) {
    var list = Networking.devices.values
    for (var i = 0; i < list.length; i++) if (list[i].type === type) return list[i]
    return null
  }

  function signalGlyph(value) {
    return glyphs[Util.clamp(Math.round(Util.clamp(value, 0, 1) * (glyphs.length - 1)), 0, glyphs.length - 1)]
  }

  function refresh() {
    var list = wifi ? wifi.networks.values.filter(function(n) { return n.name !== "" }) : []
    list.sort(function(a, b) {
      return (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)
    })
    networks = list
  }

  function togglePanel() { panel.toggleFor(root) }

  icon: kind === "ethernet" ? "󰈀" : kind === "wifi" ? signalGlyph(strength) : "󰤮"
  label: compact ? "" : kind === "ethernet" ? (wired.network ? wired.network.name : "Ethernet") : kind === "wifi" ? active.name : ""
  paddingX: compact ? Theme.spaceSm : Theme.space
  textColor: kind === "none" ? Theme.muted : Theme.foreground

  onWifiChanged: refresh()
  Connections {
    target: root.wifi ? root.wifi.networks : null
    function onValuesChanged() { root.refresh() }
  }
  // Per-network watch so a (dis)connect re-sorts the list.
  Instantiator {
    model: root.wifi ? root.wifi.networks : null
    QtObject {
      required property var modelData
      readonly property bool connected: modelData.connected
      readonly property bool known: modelData.known
      onConnectedChanged: root.refresh()
      onKnownChanged: root.refresh()
    }
  }

  onClicked: function(button) { if (button === Qt.LeftButton) togglePanel() }

  NetworkPanel {
    id: panel
    centered: root.compact
    wifi: root.wifi
    wired: root.wired
    networks: root.networks
    signalGlyph: root.signalGlyph
    onOpenedChanged: if (opened) root.refresh()
  }
}
