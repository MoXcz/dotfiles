import QtQuick
import Quickshell.Io
import qs.Commons
import qs.modules.bar.panels

// strongSwan (swanctl) tunnel state, polled through `vpn status`.
// Hidden when swanctl is not installed. Left click opens the panel, middle
// or right click toggles the connection named in Config.vpn.
BarButton {
  id: root

  // Read by WidgetSlot; binding visible directly would loop through the Loader.
  property bool shown: state !== "unavailable" || Config.vpn.alwaysShow

  // up | connecting | down | off | unavailable | nosudo, see vpn.
  property string state: "down"
  property string connection: ""
  property string virtualIp: ""
  property string remote: ""
  property string error: ""
  property bool busy: false
  readonly property bool up: state === "up"
  readonly property bool connecting: state === "connecting" || busy

  function refresh() { if (!poller.running) poller.running = true }

  function applyStatus(text) {
    var f = String(text || "").trim().split("\t")
    state = f[0] || "down"
    connection = f[1] || ""
    virtualIp = f[2] || ""
    remote = f[3] || ""
    // Poll once more while a handshake is in flight so the bar catches up.
    if (state === "connecting" && !busy) retry.restart()
  }

  function connect() { run("up") }
  function disconnect() { run("down") }
  function toggle() { run(up || connecting ? "down" : "up") }

  // `name` overrides Config.vpn.connection, used by the panel's list.
  function run(action, name) {
    if (busy) return
    error = ""
    busy = true
    action_.command = ["vpn", action, name || Config.vpn.connection]
    action_.running = true
  }

  function togglePanel() { panel.toggleFor(root) }

  icon: "󰦝"
  label: !Config.vpn.showLabel ? "" : up ? (connection || "VPN") : connecting ? "…" : ""
  textColor: up ? Theme.accent : connecting ? Theme.warning : Theme.muted

  onClicked: function(button) {
    if (button === Qt.LeftButton) togglePanel()
    else toggle()
  }

  Process {
    id: poller
    command: ["vpn", "status", Config.vpn.connection]
    stdout: StdioCollector { onStreamFinished: root.applyStatus(text) }
  }

  Process {
    id: action_
    stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
    onExited: function(code) {
      root.busy = false
      if (code !== 0 && root.error === "") root.error = "vpn exited with " + code
      root.refresh()
    }
  }

  Timer { id: retry; interval: 1500; onTriggered: root.refresh() }

  Timer {
    interval: Config.vpn.pollMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  VpnPanel {
    id: panel
    widget: root
    onOpenedChanged: if (opened) root.refresh()
  }
}
