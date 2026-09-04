pragma Singleton
import QtQuick

// One-way signals from bar widgets to the overlays that live next to the
// shell root. A widget cannot reach those instances directly, and routing
// through the IPC socket to talk to ourselves would be silly.
QtObject {
  signal menuRequested(string route)
  // The clock asks the bar to open its center panel in a mode.
  signal centerRequested(string mode)
  // A widget's panel wants to be shown inside its dock's morphing card
  // (modules/bar/DockPanel.qml), or wants that card closed.
  signal dockPanelRequested(var panel, var cell)
  signal dockPanelDismissed(var panel)
  // Only one card at a time: the center panel and the dock panels close
  // each other.
  signal dockPanelsCloseAll()
}
