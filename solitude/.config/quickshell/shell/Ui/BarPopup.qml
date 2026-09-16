import QtQuick
import qs.Commons

// Content of a bar widget's panel. Not a window: when opened it is handed
// to the bar's DockPanel (see modules/bar/DockPanel.qml), which morphs the
// widget's dock into a card and hosts this item inside it. The API a widget
// sees is unchanged from when this was a popup: openFor / toggleFor /
// dismiss, `opened`, `panelWidth`.
Item {
  id: root

  property var anchorItem: null
  property int panelWidth: 340
  property bool panelOpen: false         // owned by DockPanel; visibility also covers exit fades
  default property alias content: body.data
  readonly property bool opened: panelOpen
  // Keyboard driving. DockPanel hands every key here first; return true to
  // claim it. Escape and Tab close the card when a panel leaves them.
  function handleKey(event) { return false }

  function openFor(cell) {
    anchorItem = cell
    Bus.dockPanelRequested(root, cell)
  }

  function toggleFor(cell) {
    if (opened && anchorItem === cell) { dismiss(); return }
    openFor(cell)
  }

  function dismiss() {
    if (!opened) return
    Bus.dockPanelDismissed(root)
  }

  visible: false
  implicitHeight: body.childrenRect.height

  Item {
    id: body
    anchors.fill: parent
  }
}
