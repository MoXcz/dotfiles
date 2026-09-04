pragma Singleton
import QtQuick
import qs.Commons

// Compatibility shim for panels ported from omarchy (modules/displays).
// Omarchy reads palette roles from `Color.*`; this shell keeps them in Theme.
// Only the roles the ported code references are mapped here.
QtObject {
  readonly property color accent: Theme.accent
  readonly property color foreground: Theme.foreground
  readonly property color background: Theme.background
  readonly property color urgent: Theme.urgent
  readonly property color muted: Theme.muted

  // Omarchy popups can be themed separately from the bar; ours are one surface.
  readonly property QtObject popups: QtObject {
    readonly property color background: Theme.surface
    readonly property color text: Theme.foreground
    readonly property color border: Theme.border
  }
}
