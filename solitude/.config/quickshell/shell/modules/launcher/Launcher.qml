import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Ui

// Application launcher with three prefix modes: run in shell, run in the
// terminal, and calculator. Desktop entries come from Quickshell's
// DesktopEntries; launch counts are persisted so frequently used apps win
// ties in the ranking.
Item {
  id: root

  property bool opened: false
  // Hover only steers the cursor after the mouse has actually moved; a
  // pointer resting over the list must not steal the selection at open.
  property bool hoverArmed: false
  property var hoverOrigin: null

  // Mapping the surface under a resting pointer still yields an enter and a
  // position event; only a real displacement from the first seen point arms.
  function hoverMoved(area, mouse) {
    if (hoverArmed) return true
    var p = area.mapToItem(null, mouse.x, mouse.y)
    if (hoverOrigin === null) { hoverOrigin = p; return false }
    if (Math.abs(p.x - hoverOrigin.x) + Math.abs(p.y - hoverOrigin.y) < 4) return false
    hoverArmed = true
    return true
  }
  property string filter: ""
  property int selectedIndex: 0
  property var rows: []
  property var usage: ({})
  property string calcResult: ""
  property string calcError: ""

  readonly property var cfg: Config.launcher
  readonly property string usagePath: Config.stateDir + "/launcher-usage.json"
  readonly property string mode: {
    var f = filter
    if (f.indexOf(cfg.runPrefix) === 0) return "run"
    if (f.indexOf(cfg.terminalPrefix) === 0) return "term"
    if (f.indexOf(cfg.calcPrefix) === 0) return "calc"
    return "apps"
  }
  // Text after the mode prefix, trimmed.
  readonly property string argument: mode === "apps" ? filter.trim() : filter.slice(1).trim()

  function open() {
    filter = ""
    selectedIndex = 0
    calcResult = ""
    calcError = ""
    refresh()
    hoverArmed = false
    hoverOrigin = null
    opened = true
    keys.forceActiveFocus()
    // The list keeps its scroll offset across opens; start at the top.
    Qt.callLater(function() { list.positionViewAtBeginning() })
  }

  function close() {
    opened = false
    calcTimer.stop()
    if (calcProc.running) calcProc.running = false
  }

  function toggle() {
    if (opened) close(); else open()
  }

  function select(index) {
    if (rows.length === 0) { selectedIndex = 0; return }
    selectedIndex = (index + rows.length) % rows.length
    list.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  // ---------------------------------------------------------------- ranking
  function entryText(entry) {
    var kw = ""
    try { kw = entry.keywords.join(" ") } catch (e) { }
    return [entry.genericName, entry.comment, kw].join(" ")
  }

  function iconFor(entry) {
    var icon = String(entry.icon || "")
    if (icon.charAt(0) === "/") return Util.fileUrl(icon)
    var path = icon ? Quickshell.iconPath(icon, true) : ""
    return path || Quickshell.iconPath("application-x-executable", true)
  }

  function appRows(query) {
    var values = DesktopEntries.applications.values || []
    var out = []
    for (var i = 0; i < values.length; i++) {
      var entry = values[i]
      if (!entry || entry.noDisplay) continue
      var name = String(entry.name || entry.id || "")
      if (!name) continue
      var score = Util.fuzzyScore(query, name)
      if (score < 0) {
        // Secondary fields only count as weak matches so name hits stay on top.
        var alt = Util.fuzzyScore(query, entryText(entry))
        if (alt < 0) continue
        score = 500 + alt
      }
      out.push({
        kind: "app", entry: entry, title: name,
        subtitle: String(entry.comment || entry.genericName || ""),
        icon: iconFor(entry), glyph: "",
        score: score, uses: Number(usage[entry.id] || 0), key: name.toLowerCase()
      })
    }
    out.sort(function(a, b) {
      if (a.score !== b.score) return a.score - b.score
      if (a.uses !== b.uses) return b.uses - a.uses
      return a.key < b.key ? -1 : (a.key > b.key ? 1 : 0)
    })
    return out
  }

  function hintRow(glyph, title, subtitle) {
    return { kind: "hint", title: title, subtitle: subtitle, icon: "", glyph: glyph, entry: null }
  }

  function refresh() {
    var next = []
    if (mode === "apps") {
      next = appRows(argument)
    } else if (mode === "run") {
      next = [argument ? { kind: "run", title: argument, subtitle: "Run in shell", icon: "", glyph: "", entry: null }
                       : hintRow("", "Run command", "Type a command to run it in a shell")]
    } else if (mode === "term") {
      next = [argument ? { kind: "term", title: argument, subtitle: "Run in " + Config.terminal, icon: "", glyph: "", entry: null }
                       : hintRow("", "Run in terminal", "Type a command to run it inside " + Config.terminal)]
    } else if (!argument) {
      next = [hintRow("󰃬", "Calculator", "Type an expression, Enter copies the result")]
    } else if (calcError) {
      next = [hintRow("󰃬", "…", calcError)]
    } else {
      next = [{ kind: "calc", title: calcResult || "…", subtitle: argument, icon: "", glyph: "󰃬", entry: null }]
    }
    rows = next
    if (selectedIndex >= next.length) selectedIndex = 0
  }

  onFilterChanged: {
    selectedIndex = 0
    if (mode === "calc" && argument) calcTimer.restart()
    refresh()
  }

  // ---------------------------------------------------------------- actions
  function activate() {
    var row = rows[selectedIndex]
    if (!row) return
    if (row.kind === "app") {
      var id = String(row.entry.id || "")
      usage[id] = Number(usage[id] || 0) + 1
      usageFile.setText(JSON.stringify(usage) + "\n")
      row.entry.execute()
    } else if (row.kind === "run") {
      Util.exec(row.title)
    } else if (row.kind === "term") {
      Util.execArgv([Config.terminal, "-e", "bash", "-lc", row.title])
    } else if (row.kind === "calc") {
      if (!calcResult) return
      Quickshell.execDetached(["wl-copy", "--", calcResult])
    } else {
      return
    }
    close()
  }

  function handleKey(event) {
    var ctrl = event.modifiers & Qt.ControlModifier
    event.accepted = true
    switch (event.key) {
    case Qt.Key_Escape: close(); return
    case Qt.Key_Down: case Qt.Key_Tab: select(selectedIndex + 1); return
    case Qt.Key_Up: case Qt.Key_Backtab: select(selectedIndex - 1); return
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

  // ---------------------------------------------------------------- state
  Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Config.stateDir])

  FileView {
    id: usageFile
    path: root.usagePath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try { root.usage = JSON.parse(text()) || {} } catch (e) { root.usage = {} }
      if (root.opened) root.refresh()
    }
    onLoadFailed: root.usage = {}
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() { if (root.opened) root.refresh() }
  }

  // Debounce so a keystroke burst spawns one interpreter, not one per key.
  Timer {
    id: calcTimer
    interval: 120
    onTriggered: {
      if (calcProc.running) calcProc.running = false
      calcProc.command = ["python3", "-c", "from math import *; print(" + root.argument + ")"]
      calcProc.running = true
    }
  }

  Process {
    id: calcProc
    stdout: StdioCollector { id: calcOut }
    stderr: StdioCollector { id: calcErr }
    onExited: function(code) {
      if (root.mode !== "calc") return
      if (code === 0) {
        root.calcResult = String(calcOut.text).trim()
        root.calcError = ""
      } else {
        root.calcResult = ""
        var lines = String(calcErr.text).trim().split("\n")
        root.calcError = lines[lines.length - 1] || "error"
      }
      root.refresh()
    }
  }

  // ---------------------------------------------------------------- ui
  Overlay {
    id: overlay
    opened: root.opened
    namespace: "shell-launcher"
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
        height: header.implicitHeight + separator.height + list.height + Theme.spaceSm * 2

        Column {
          anchors.fill: parent
          anchors.topMargin: Theme.spaceSm
          anchors.bottomMargin: Theme.spaceSm

          SearchField {
            id: header
            width: parent.width
            text: root.filter
            placeholder: root.cfg.placeholder
          }

          Rectangle {
            id: separator
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
          }

          ListView {
            id: list
            width: parent.width
            height: Math.min(root.rows.length, root.cfg.maxRows) * root.cfg.rowHeight
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

              Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spaceLg
                anchors.rightMargin: Theme.spaceLg
                spacing: Theme.space

                Item {
                  width: Theme.fontTitle * 2
                  height: parent.height

                  IconImage {
                    anchors.centerIn: parent
                    implicitSize: Theme.fontTitle * 1.6
                    source: row.modelData.icon
                    visible: row.modelData.icon.length > 0
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: row.modelData.icon.length === 0
                    text: row.modelData.glyph
                    color: row.selected ? Theme.accent : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontHeading
                  }
                }

                Column {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - Theme.fontTitle * 2 - parent.spacing

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
                    text: row.modelData.subtitle
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    elide: Text.ElideRight
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
