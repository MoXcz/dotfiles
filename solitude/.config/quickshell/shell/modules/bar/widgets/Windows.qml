import QtQuick
import Quickshell.Io
import qs.Commons
import qs.modules.bar.panels

// Windows VM (dockur/windows in Docker) state, polled through
// `windows-vm state`. Hidden until the VM is installed. Left click
// opens the panel, middle or right click starts or stops the VM.
BarButton {
  id: root

  // Read by WidgetSlot; binding visible directly would loop through the Loader.
  property bool shown: state !== "unavailable" || Config.windows.alwaysShow

  // unavailable | off | booting | up, see windows-vm state.
  property string state: "off"
  property string detail: ""
  property string error: ""
  property bool busy: false
  readonly property bool up: state === "up"
  readonly property bool running: state === "up" || state === "booting"
  readonly property bool booting: state === "booting" || busy

  function refresh() { if (!poller.running) poller.running = true }

  function applyState(text) {
    var f = String(text || "").trim().split("\t")
    state = f[0] || "off"
    detail = f[1] || ""
    // Poll faster while the guest boots so the bar catches up.
    if (state === "booting" && !busy) retry.restart()
  }

  function start() { run("up") }
  function stop() { run("stop") }
  function toggle() { run(running ? "stop" : "up") }
  // Opens RDP fullscreen; -k keeps the VM up after the session so the bar
  // toggle stays the single owner of the VM lifecycle.
  function connect() { Util.execArgv(["windows-vm", "launch", "-k"]) }
  function console_() { Util.execArgv(["xdg-open", "http://127.0.0.1:8006"]) }

  function run(action) {
    if (busy) return
    error = ""
    busy = true
    action_.command = ["windows-vm", action]
    action_.running = true
  }

  function togglePanel() { panel.toggleFor(root) }

  panelActive: panel.opened

  icon: "󰖳"
  label: !Config.windows.showLabel ? "" : booting ? "…" : ""
  textColor: up ? Theme.accent : booting ? Theme.warning : Theme.muted

  onClicked: function(button) {
    if (button === Qt.LeftButton) togglePanel()
    else toggle()
  }

  Process {
    id: poller
    command: ["windows-vm", "state"]
    stdout: StdioCollector { onStreamFinished: root.applyState(text) }
  }

  Process {
    id: action_
    stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
    onExited: function(code) {
      root.busy = false
      if (code !== 0 && root.error === "") root.error = "windows-vm exited with " + code
      root.refresh()
    }
  }

  Timer { id: retry; interval: 3000; onTriggered: root.refresh() }

  Timer {
    interval: Config.windows.pollMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WindowsPanel {
    id: panel
    widget: root
    onOpenedChanged: if (opened) root.refresh()
  }
}
