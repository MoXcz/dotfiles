import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import Quickshell.Widgets
import "Routes.js" as Routes

// Command palette in the bar's shared morphing panel. The root is one searchable
// list of every action; pickers (keyboard, emoji) are the only nested
// routes. Routes are plain data (see Routes.js), so adding an entry never
// means touching the view.
//
// Opened with Super+Shift+D, a middle click on the clock, or from outside:
//   shell menu toggle [route]
Item {
  id: root

  required property var bar
  readonly property bool opened: panel.opened
  property string filter: ""
  property int selectedIndex: 0
  // Route ids from the root down to the visible one, e.g. ["root", "capture"].
  property var stack: ["root"]
  // -1 when a route was pushed, +1 when popped; the sign the route transition
  // slides in from.
  property int slide: 0
  property var dynamicRows: null      // rows fetched by a generator route
  // Which of the commands rows depend on are actually installed. Probed once
  // at startup; a row needing a missing command is not offered.
  property var available: ({})
  property string loadingLabel: ""

  readonly property var cfg: Config.menu
  readonly property string route: stack[stack.length - 1]
  readonly property var node: Routes.node(route)

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

  // ---------------------------------------------------------------- rows
  readonly property var rows: {
    // A generator route has no static rows, so it reads as undefined until
    // its command comes back.
    var source = dynamicRows !== null ? dynamicRows : ((node && node.rows) ? node.rows : [])
    var all = []
    for (var a = 0; a < source.length; a++) {
      var need = source[a].requires
      if (need && !available[need]) continue
      all.push(source[a])
    }
    var query = filter.trim()
    if (!query) return all
    var out = []
    for (var i = 0; i < all.length; i++) {
      var score = Util.fuzzyScore(query, all[i].title + " " + (all[i].subtitle || ""))
      if (score < 0) continue
      out.push({ row: all[i], score: score })
    }
    out.sort(function(a, b) { return a.score - b.score })
    return out.map(function(e) { return e.row })
  }

  // ---------------------------------------------------------------- open/close
  function open(target) {
    var anchor = bar.clockSlotForFocus()
    if (!anchor) return
    var start = String(target || "root")
    if (!Routes.node(start)) start = "root"
    stack = start === "root" ? ["root"] : ["root", start]
    slide = 0
    enter(start)
    hoverArmed = false
    hoverOrigin = null
    opening()
    panel.openFor(anchor)
  }

  function close() {
    panel.dismiss()
    generator.running = false
    dynamicRows = null
    loadingLabel = ""
  }

  // Raised before opening so the shell can close the other overlays.
  signal opening()

  function ownsPanel(candidate) { return candidate === panel }

  function toggle(target) {
    // Re-invoking the bind for the route already on screen closes it; a
    // different route re-points the open menu instead of shutting it.
    if (opened && (!target || target === route)) { close(); return }
    open(target)
  }

  // A route whose rows come from a command loads them on entry.
  function enter(id) {
    filter = ""
    selectedIndex = 0
    dynamicRows = null
    generator.running = false
    var n = Routes.node(id)
    if (n && n.generator) {
      loadingLabel = n.loading || "Loading…"
      generator.command = n.generator
      generator.running = true
    } else {
      loadingLabel = ""
    }
  }

  function push(id) {
    if (!Routes.node(id)) return
    slide = -1
    stack = stack.concat([id])
    enter(id)
  }

  function pop() {
    if (stack.length <= 1) { close(); return }
    slide = 1
    var next = stack.slice(0, stack.length - 1)
    stack = next
    enter(next[next.length - 1])
  }

  function select(index) {
    if (rows.length === 0) { selectedIndex = 0; return }
    // Wrapping needs a positive modulus: stepping up from the first row moves
    // past the first row, which is more than -rows.length.
    var count = rows.length
    selectedIndex = ((index % count) + count) % count
    list.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  // ---------------------------------------------------------------- activate
  function activate() {
    var row = rows[selectedIndex]
    if (!row) return
    if (row.route) { push(row.route); return }
    if (row.copy !== undefined) {
      Quickshell.execDetached(["wl-copy", "--", String(row.copy)])
      close()
      return
    }
    if (row.argv) { Util.execArgv(row.argv); close(); return }
    if (row.command) { Util.exec(row.command); close(); return }
  }

  function handleKey(event) {
    var ctrl = event.modifiers & Qt.ControlModifier
    event.accepted = true
    switch (event.key) {
    case Qt.Key_Escape: close(); return
    case Qt.Key_Tab: select(selectedIndex + 1); return
    case Qt.Key_Backtab: select(selectedIndex - 1); return
    case Qt.Key_Down: select(selectedIndex + 1); return
    case Qt.Key_Up: select(selectedIndex - 1); return
    case Qt.Key_Right: activate(); return
    case Qt.Key_Left: if (!filter) { pop(); return } break
    case Qt.Key_J: case Qt.Key_N: if (ctrl) { select(selectedIndex + 1); return } break
    case Qt.Key_K: case Qt.Key_P: if (ctrl) { select(selectedIndex - 1); return } break
    case Qt.Key_H: if (ctrl) { pop(); return } break
    case Qt.Key_Return: case Qt.Key_Enter: activate(); return
    case Qt.Key_Backspace:
      // Backspace on an empty filter walks back up the route stack.
      if (!filter) { pop(); return }
      break
    }
    if (Util.editsFilter(event, filter)) { filter = Util.editedFilter(event, filter); return }
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) { event.accepted = false; return }
    var text = String(event.text || "")
    if (text.length > 0 && text.charCodeAt(0) >= 32) filter += text
    else event.accepted = false
  }

  onFilterChanged: selectedIndex = 0
  onRowsChanged: if (selectedIndex >= rows.length) selectedIndex = 0

  // One probe for every command the routes name, at startup rather than per
  // open, so the list never waits on a subprocess to render.
  Process {
    id: probe
    running: true
    command: ["bash", "-lc",
      'for c in ' + Routes.requirements().join(" ") + '; do command -v "$c" >/dev/null 2>&1 && echo "$c"; done']
    stdout: StdioCollector {
      onStreamFinished: {
        var found = {}
        var names = String(text).trim().split("\n")
        for (var i = 0; i < names.length; i++) {
          if (names[i]) found[names[i]] = true
        }
        root.available = found
      }
    }
  }

  // Generator routes print one row per line as "glyph<TAB>title<TAB>payload".
  // The payload is passed to the route's `run` template as $1, never expanded
  // into a shell string here.
  Process {
    id: generator
    stdout: StdioCollector {
      onStreamFinished: {
        var n = Routes.node(root.route)
        if (!n || !n.generator) return
        root.dynamicRows = Routes.parseRows(text, n)
        root.loadingLabel = ""
      }
    }
    onExited: function(code) {
      if (code !== 0 && root.dynamicRows === null) {
        root.dynamicRows = []
        root.loadingLabel = "Nothing to show"
      }
    }
  }

  // ---------------------------------------------------------------- ui
  Connections {
    target: Bus
    function onMenuRequested(route) { root.toggle(route) }
  }

  BarPopup {
    id: panel
    panelWidth: root.cfg.width

    function handleKey(event) { root.handleKey(event); return event.accepted }

    Column {
      width: parent.width

          SearchField {
            id: header
            width: parent.width
            text: root.filter
            icon: root.stack.length > 1 ? "" : "󰍉"
            placeholder: root.node ? root.node.title : "Search actions…"
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
            height: Math.max(root.cfg.rowHeight,
                             Math.min(root.rows.length, root.cfg.maxRows) * root.cfg.rowHeight)

            Text {
              anchors.centerIn: parent
              visible: root.rows.length === 0
              text: root.loadingLabel.length > 0 ? root.loadingLabel : "No matches"
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

              transform: Translate { id: listSlide }
              onModelChanged: if (root.slide !== 0) listSlideIn.restart()

              NumberAnimation {
                id: listSlideIn
                target: listSlide
                property: "x"
                from: root.slide * root.cfg.slidePx
                to: 0
                duration: root.cfg.animationMs
                easing.type: Easing.OutCubic
              }

              // Step 5: rows arrive staggered. The delay is capped, or the
              // 1810-row emoji list would queue a 36-second animation.
              populate: Transition {
                SequentialAnimation {
                  PauseAnimation { duration: Math.max(0, Math.min(ViewTransition.index * 12, 120)) }
                  NumberAnimation {
                    property: "opacity"; from: 0; to: 1
                    duration: root.cfg.animationMs; easing.type: Easing.OutCubic
                  }
                }
              }

              delegate: Rectangle {
                id: row
                required property int index
                required property var modelData
                readonly property bool selected: index === root.selectedIndex
                width: ListView.view.width
                height: root.cfg.rowHeight
                color: selected ? Theme.selected : (hoverArea.containsMouse ? Theme.hover : "transparent")
                Behavior on color { ColorAnimation { duration: 90 } }

                Rectangle {
                  width: 2
                  height: parent.height
                  color: Theme.accent
                  visible: row.selected
                }

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: Theme.spaceLg
                  anchors.rightMargin: Theme.spaceLg
                  spacing: Theme.space

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.fontTitle * 1.8
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.glyph || ""
                    color: row.selected ? Theme.accent : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontHeading
                  }

                  Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.fontTitle * 1.8 - parent.spacing * 2 - chevron.width

                    Text {
                      width: parent.width
                      text: row.modelData.title
                      color: Theme.foreground
                      font.family: Theme.fontFamily
                      font.pixelSize: Theme.fontBody
                      elide: Text.ElideRight
                    }

                    Text {
                      width: parent.width
                      visible: text.length > 0
                      text: row.modelData.subtitle || ""
                      color: Theme.muted
                      font.family: Theme.fontFamily
                      font.pixelSize: Theme.fontCaption
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    id: chevron
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.modelData.route ? Theme.fontBody : 0
                    text: row.modelData.route ? "" : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
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
