import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Searchable list of every Hyprland bind, in the launcher's frame. Rows come
// from `keybindings` (one "glyph<TAB>combo<TAB>combo<TAB>description"
// line each), read fresh on every open so a Hyprland reload is reflected.
// Enter copies the key combination.
Item {
  id: root

  property bool opened: false
  property string filter: ""
  property int selectedIndex: 0
  property var entries: []        // every bind, as parsed
  property var rows: []           // entries matching the filter
  property string status: ""      // "Reading binds…" until the generator returns

  // Hover only steers the selection once the pointer has actually moved, so a
  // pointer resting where the list appears cannot steal it at open.
  property bool hoverArmed: false
  property var hoverOrigin: null

  function hoverMoved(area, mouse) {
    if (hoverArmed) return true
    var p = area.mapToItem(null, mouse.x, mouse.y)
    if (hoverOrigin === null) { hoverOrigin = p; return false }
    if (Math.abs(p.x - hoverOrigin.x) + Math.abs(p.y - hoverOrigin.y) < 4) return false
    hoverArmed = true
    return true
  }

  readonly property var cfg: Config.keybindings

  function open() {
    filter = ""
    selectedIndex = 0
    hoverArmed = false
    hoverOrigin = null
    opened = true
    keys.forceActiveFocus()
    status = "Reading binds…"
    if (generator.running) generator.running = false
    generator.running = true
    Qt.callLater(function() { list.positionViewAtBeginning() })
  }

  function close() {
    opened = false
    if (generator.running) generator.running = false
  }

  function toggle() { opened ? close() : open() }

  function select(index) {
    if (rows.length === 0) { selectedIndex = 0; return }
    selectedIndex = ((index % rows.length) + rows.length) % rows.length
    list.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function parse(text) {
    var out = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split("\t")
      if (parts.length < 4 || !parts[1]) continue
      out.push({ combo: parts[1], description: parts[3] })
    }
    return out
  }

  function applyFilter() {
    var q = filter.trim()
    if (!q) { rows = entries; return }
    var scored = []
    for (var i = 0; i < entries.length; i++) {
      var e = entries[i]
      var score = Util.fuzzyScore(q, e.description + " " + e.combo)
      if (score >= 0) scored.push({ row: e, score: score })
    }
    scored.sort(function(a, b) { return a.score - b.score })
    rows = scored.map(function(s) { return s.row })
  }

  onFilterChanged: { selectedIndex = 0; applyFilter() }
  onRowsChanged: if (selectedIndex >= rows.length) selectedIndex = 0

  function activate() {
    var row = rows[selectedIndex]
    if (!row) return
    Quickshell.execDetached(["wl-copy", "--", row.combo])
    close()
  }

  function handleKey(event) {
    var ctrl = event.modifiers & Qt.ControlModifier
    event.accepted = true
    switch (event.key) {
    case Qt.Key_Escape: close(); return
    case Qt.Key_Down: case Qt.Key_Tab: select(selectedIndex + 1); return
    case Qt.Key_Up: case Qt.Key_Backtab: select(selectedIndex - 1); return
    case Qt.Key_PageDown: select(selectedIndex + cfg.maxRows); return
    case Qt.Key_PageUp: select(selectedIndex - cfg.maxRows); return
    case Qt.Key_J: case Qt.Key_N: if (ctrl) { select(selectedIndex + 1); return } break
    case Qt.Key_K: case Qt.Key_P: if (ctrl) { select(selectedIndex - 1); return } break
    case Qt.Key_Return: case Qt.Key_Enter: activate(); return
    }
    if (Util.editsFilter(event, filter)) { filter = Util.editedFilter(event, filter); return }
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) { event.accepted = false; return }
    var text = String(event.text || "")
    if (text.length > 0 && text.charCodeAt(0) >= 32) filter += text
    else event.accepted = false
  }

  Process {
    id: generator
    command: ["keybindings"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.entries = root.parse(text)
        root.status = root.entries.length > 0 ? "" : "No binds reported"
        root.applyFilter()
      }
    }
    onExited: function(code) {
      if (code !== 0 && root.entries.length === 0) root.status = "keybindings failed"
    }
  }

  // ---------------------------------------------------------------- ui
  Overlay {
    id: overlay
    opened: root.opened
    namespace: "shell-keybindings"
    onDismissed: root.close()

    Item {
      id: keys
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(event) { root.handleKey(event) }

      Card {
        id: card
        width: root.cfg.width
        x: Math.round((parent.width - width) / 2)
        y: Math.round(parent.height / 4)
        height: header.implicitHeight + separator.height + body.height + Theme.spaceSm * 2

        Column {
          anchors.fill: parent
          anchors.topMargin: Theme.spaceSm
          anchors.bottomMargin: Theme.spaceSm

          SearchField {
            id: header
            width: parent.width
            text: root.filter
            icon: "󰌌"
            placeholder: root.cfg.placeholder
          }

          Rectangle {
            id: separator
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
          }

          Item {
            id: body
            width: parent.width
            height: Math.max(root.cfg.rowHeight, Math.min(root.rows.length, root.cfg.maxRows) * root.cfg.rowHeight)

            Text {
              anchors.centerIn: parent
              visible: root.rows.length === 0
              text: root.status.length > 0 ? root.status : "No matches"
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontBody
            }

            ListView {
              id: list
              anchors.fill: parent
              model: root.rows
              currentIndex: root.selectedIndex
              highlightMoveDuration: 0
              clip: true
              boundsBehavior: Flickable.StopAtBounds

              delegate: Rectangle {
                id: row
                required property int index
                required property var modelData
                readonly property bool selected: index === root.selectedIndex
                width: ListView.view.width
                height: root.cfg.rowHeight
                color: selected ? Theme.selected : (hoverArea.containsMouse ? Theme.hover : "transparent")

                Rectangle {
                  width: 2
                  height: parent.height
                  color: Theme.accent
                  visible: row.selected
                }

                Item {
                  anchors.fill: parent
                  anchors.leftMargin: Theme.spaceLg
                  anchors.rightMargin: Theme.spaceLg

                  Text {
                    id: description
                    anchors.left: parent.left
                    anchors.right: combo.left
                    anchors.rightMargin: Theme.space
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.description
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    elide: Text.ElideRight
                  }

                  // The combo reads as a key cap: accent text in a bordered pill.
                  Rectangle {
                    id: combo
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: comboText.implicitWidth + Theme.space * 2
                    height: comboText.implicitHeight + Theme.spaceSm * 2
                    radius: Theme.cornerRadius / 2
                    color: Theme.surfaceAlt
                    border.width: Theme.borderWidth
                    border.color: row.selected ? Theme.accent : Theme.border

                    Text {
                      id: comboText
                      anchors.centerIn: parent
                      text: row.modelData.combo
                      color: row.selected ? Theme.accent : Theme.muted
                      font.family: Theme.fontFamily
                      font.pixelSize: Theme.fontCaption
                    }
                  }
                }

                MouseArea {
                  id: hoverArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: if (root.hoverArmed) root.selectedIndex = row.index
                  onPositionChanged: function(mouse) { if (root.hoverMoved(this, mouse)) root.selectedIndex = row.index }
                  onClicked: { root.selectedIndex = row.index; root.activate() }
                }
              }
            }
          }
        }
      }
    }
  }
}
