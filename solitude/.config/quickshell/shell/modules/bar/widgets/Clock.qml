import QtQuick
import qs.Commons

// Date/time readout. Left click morphs the pill into the center panel on
// its calendar; right click swaps between the two configured formats;
// middle click opens the command menu. "{w}" in a format prints the ISO week number. The tick
// rate only goes to one second when the visible format prints seconds.
BarButton {
  id: root

  property bool alt: false
  property date now: new Date()
  readonly property string format: alt ? Config.bar.clockFormatAlt : Config.bar.clockFormat

  function togglePanel() { Bus.centerRequested("calendar") }

  label: Util.formatTime(now, format)

  onClicked: function(button) {
    if (button === Qt.LeftButton) { togglePanel(); return }
    if (button === Qt.MiddleButton) { Bus.menuRequested("root"); return }
    alt = !alt
    now = new Date()
  }

  Timer {
    interval: root.format.indexOf("ss") >= 0 ? 1000 : 10000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }
}
