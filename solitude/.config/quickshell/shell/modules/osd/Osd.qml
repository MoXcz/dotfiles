import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

// On-screen display for volume and brightness. Volume follows the default
// Pipewire sink and pops up on its own when it changes; brightness is read
// from brightnessctl on request (keybindings call `shell osd
// brightness` after changing it).
Item {
  id: root

  property bool showing: false
  property string kind: "volume"
  property int value: 0
  property bool muted: false

  readonly property var cfg: Config.osd
  readonly property PwNode sink: Pipewire.defaultAudioSink
  // Pipewire reports the sink's current volume once at bind time; only
  // changes after that should raise the OSD.
  property bool armed: false

  PwObjectTracker { objects: [root.sink] }

  Timer {
    id: armTimer
    interval: 1000
    running: true
    onTriggered: root.armed = true
  }

  onSinkChanged: { armed = false; armTimer.restart() }

  Connections {
    target: root.sink ? root.sink.audio : null
    function onVolumeChanged() { if (root.armed) root.showVolume() }
    function onMutedChanged() { if (root.armed) root.showVolume() }
  }

  function showVolume() {
    var audio = sink ? sink.audio : null
    kind = "volume"
    muted = audio ? audio.muted : false
    value = audio ? Math.round(audio.volume * 100) : 0
    present()
  }

  function showBrightness() {
    brightnessProc.running = true
  }

  function present() {
    if (!showing) panel.screen = focusedScreen()
    showing = true
    hideTimer.restart()
  }

  function focusedScreen() {
    var monitor = Hyprland.focusedMonitor
    var screens = Quickshell.screens
    if (monitor) {
      for (var i = 0; i < screens.length; i++) {
        if (screens[i].name === monitor.name) return screens[i]
      }
    }
    return screens.length > 0 ? screens[0] : null
  }

  function glyph() {
    if (kind === "brightness") return value < 50 ? "󰃞" : "󰃠"
    if (muted || value === 0) return "󰝟"
    return value < 34 ? "󰕿" : value < 67 ? "󰖀" : "󰕾"
  }

  Timer {
    id: hideTimer
    interval: root.cfg.timeoutMs
    onTriggered: root.showing = false
  }

  Process {
    id: brightnessProc
    command: ["brightnessctl", "-m"]
    stdout: StdioCollector {
      // Machine-readable line: device,class,current,percent,max
      onStreamFinished: {
        var fields = String(text).split("\n")[0].split(",")
        var pct = parseInt(String(fields[3] || "").replace("%", ""), 10)
        if (!isFinite(pct)) return
        root.kind = "brightness"
        root.muted = false
        root.value = Util.clamp(pct, 0, 100)
        root.present()
      }
    }
  }

  PanelWindow {
    id: panel
    visible: root.showing
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "shell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Purely visual: never intercept clicks meant for what is underneath.
    mask: Region {}

    // Unanchored axes are centered by the compositor.
    anchors.top: root.cfg.position === "top-center"
    anchors.bottom: root.cfg.position === "bottom-center"
    margins.top: root.cfg.margin
    margins.bottom: root.cfg.margin
    implicitWidth: root.cfg.width
    implicitHeight: card.implicitHeight

    Card {
      id: card
      anchors.fill: parent
      implicitHeight: Theme.fontHeading + Theme.spaceLg * 2

      Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceLg
        anchors.rightMargin: Theme.spaceLg
        spacing: Theme.spaceLg

        Text {
          id: icon
          anchors.verticalCenter: parent.verticalCenter
          width: Theme.fontHeading * 1.5
          text: root.glyph()
          color: root.muted ? Theme.urgent : Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontHeading
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - icon.width - percent.width - parent.spacing * 2
          height: Theme.spaceSm + 2
          radius: height / 2
          color: Theme.surfaceAlt

          Rectangle {
            height: parent.height
            width: parent.width * Math.min(root.value, 100) / 100
            radius: parent.radius
            color: root.muted ? Theme.urgent : Theme.accent
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
          }
        }

        Text {
          id: percent
          anchors.verticalCenter: parent.verticalCenter
          width: percentMetrics.advanceWidth
          horizontalAlignment: Text.AlignRight
          text: root.value + "%"
          color: root.muted ? Theme.muted : Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontBody
          font.bold: true
        }
      }
    }
  }

  // Widest readout the label can show, so the bar does not jump between 9% and 100%.
  TextMetrics {
    id: percentMetrics
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    font.bold: true
    text: "100%"
  }
}
