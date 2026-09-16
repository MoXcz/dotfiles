import QtQuick
import Quickshell.Services.Pipewire
import qs.Commons
import qs.modules.bar.panels

// Default sink volume. Wheel steps 5%, left click opens the devices panel,
// middle / right click toggles mute.
BarButton {
  id: root

  // Read by WidgetSlot; binding visible directly would loop through the Loader.
  property bool shown: ready

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink !== null && sink.audio !== null
  readonly property real volume: ready ? sink.audio.volume : 0
  readonly property bool muted: ready ? sink.audio.muted : false
  readonly property int percent: Math.round(volume * 100)

  // Volume and mute are only readable while the node is bound.
  PwObjectTracker { objects: root.sink ? [root.sink] : [] }

  function togglePanel() { panel.toggleFor(root) }

  icon: muted ? "󰝟" : percent === 0 ? "󰕿" : percent < 50 ? "󰖀" : "󰕾"
  label: percent + "%"
  textColor: muted ? Theme.muted : Theme.foreground
  panelActive: panel.opened

  onClicked: function(button) {
    if (button === Qt.LeftButton) togglePanel()
    else if (ready) sink.audio.muted = !sink.audio.muted
  }

  onScrolled: function(delta) {
    if (ready) sink.audio.volume = Util.clamp(volume + (delta > 0 ? 0.05 : -0.05), 0, 1)
  }

  AudioPanel { id: panel }
}
