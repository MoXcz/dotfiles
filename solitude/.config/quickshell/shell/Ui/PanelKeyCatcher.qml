import QtQuick

// Key dispatcher for keyboard-driven panels. Wraps the panel content and
// turns raw keys into semantic signals so the panel keeps only its own
// state machine. Keys.BeforeItem lets it win over inner Flickables; a panel
// with an inline editor sets `blocked` while the editor has focus so typing
// reaches it (omarchy kit port; modules/displays).
Item {
  id: root

  property bool blocked: false

  signal moveRequested(int dx, int dy)
  signal activateRequested()
  signal returnRequested()
  signal closeRequested()
  signal deleteRequested()
  signal tabRequested(int direction)
  signal textKey(string text)

  focus: true
  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (blocked) return

    if (event.key === Qt.Key_Escape) { closeRequested(); event.accepted = true; return }
    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
      tabRequested((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1)
      event.accepted = true
      return
    }
    // Modified arrows are claimed by the panel's Shortcut items (fine nudges).
    var plain = (event.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier)) === 0
    if ((event.key === Qt.Key_Down && plain) || event.text === "j") { moveRequested(0, 1); event.accepted = true; return }
    if ((event.key === Qt.Key_Up && plain) || event.text === "k") { moveRequested(0, -1); event.accepted = true; return }
    if ((event.key === Qt.Key_Right && plain) || event.text === "l") { moveRequested(1, 0); event.accepted = true; return }
    if ((event.key === Qt.Key_Left && plain) || event.text === "h") { moveRequested(-1, 0); event.accepted = true; return }
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      returnRequested()
      activateRequested()
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Space) { activateRequested(); event.accepted = true; return }
    if (event.text === "x" || event.text === "X") { deleteRequested(); event.accepted = true; return }
    if (event.text && event.text.length === 1) textKey(event.text)
  }
}
