import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Clipboard history: two wl-paste watchers feed capture.sh, which appends
// JSON lines to history.jsonl; this component reads that file and offers
// a searchable picker that copies (and optionally pastes) an old entry.
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

  readonly property string stateDir: Config.stateDir + "/clipboard"
  readonly property string itemsDir: stateDir + "/items"
  readonly property string historyPath: stateDir + "/history.jsonl"
  readonly property string captureScript: Quickshell.shellDir + "/modules/clipboard/capture.sh"

  property var entries: []        // newest first, unique by id
  property var rows: []           // entries matching the filter
  property string filter: ""
  property int selected: 0
  property bool confirmClear: false
  property bool trimmedThisOpen: false
  property real now: Date.now() / 1000
  property var pendingPaste: null

  readonly property var current: selected >= 0 && selected < rows.length ? rows[selected] : null

  function open() {
    if (opened) return
    filter = ""
    selected = 0
    confirmClear = false
    trimmedThisOpen = false
    now = Date.now() / 1000
    hoverArmed = false
    hoverOrigin = null
    opened = true
    historyFile.reload()
    keys.forceActiveFocus()
  }

  function close() { opened = false }
  function toggle() { opened ? close() : open() }

  Component.onCompleted: initProc.running = true

  // ---------------------------------------------------------------- history
  function loadHistory(raw) {
    var lines = String(raw || "").split("\n")
    var byId = ({})
    var order = []
    for (var i = lines.length - 1; i >= 0; i--) {
      var line = lines[i].trim()
      if (!line) continue
      var entry
      try { entry = JSON.parse(line) } catch (e) { continue }
      if (!entry || !entry.id || byId[entry.id]) continue
      byId[entry.id] = true
      order.push(entry)
    }
    var limit = Math.max(1, Number(Config.clipboard.historyLimit) || 300)
    var dirty = order.length < lines.filter(function(l) { return l.trim() }).length
    if (order.length > limit) {
      var dropped = order.slice(limit)
      order = order.slice(0, limit)
      dirty = true
      var files = dropped.map(function(e) { return e.file }).filter(function(f) { return f })
      if (files.length > 0) Util.execArgv(["rm", "-f"].concat(files))
    }
    entries = order
    applyFilter()
    if (dirty && opened && !trimmedThisOpen) {
      trimmedThisOpen = true
      writeHistory()
    }
  }

  function writeHistory() {
    var lines = []
    for (var i = entries.length - 1; i >= 0; i--) lines.push(JSON.stringify(entries[i]))
    historyFile.setText(lines.length > 0 ? lines.join("\n") + "\n" : "")
  }

  function applyFilter() {
    var q = filter.trim()
    var out = []
    for (var i = 0; i < entries.length; i++) {
      var e = entries[i]
      if (!q || Util.fuzzyScore(q, e.text || "") >= 0) out.push(e)
    }
    rows = out
    if (selected >= rows.length) selected = Math.max(0, rows.length - 1)
  }

  function relativeTime(epoch) {
    var diff = Math.max(0, now - Number(epoch || 0))
    if (diff < 60) return "just now"
    if (diff < 3600) return Math.floor(diff / 60) + "m ago"
    if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
    return Math.floor(diff / 86400) + "d ago"
  }

  function formatBytes(n) {
    n = Number(n) || 0
    if (n < 1024) return n + " B"
    if (n < 1048576) return (n / 1024).toFixed(1) + " KB"
    return (n / 1048576).toFixed(1) + " MB"
  }

  function firstLine(text) {
    var s = String(text || "").replace(/^\s+/, "")
    var nl = s.indexOf("\n")
    return nl >= 0 ? s.slice(0, nl) : s
  }

  // ---------------------------------------------------------------- actions
  function activate() {
    var entry = current
    if (!entry || !entry.file) return
    var argv = entry.type === "image" ? ["--type", "image/png"] : []
    pendingPaste = Config.clipboard.pasteOnSelect ? entry : null
    copyProc.exec(["bash", "-c", 'exec wl-copy "$@" < "$0"', entry.file].concat(argv))
    close()
  }

  function removeCurrent() {
    var entry = current
    if (!entry) return
    entries = entries.filter(function(e) { return e.id !== entry.id })
    if (entry.file) Util.execArgv(["rm", "-f", entry.file])
    applyFilter()
    writeHistory()
  }

  function clearAll() {
    confirmClear = false
    entries = []
    applyFilter()
    Util.exec("rm -f " + Util.shellQuote(itemsDir) + "/*")
    historyFile.setText("")
  }

  function move(delta) {
    if (rows.length === 0) return
    selected = (selected + delta + rows.length) % rows.length
  }

  function handleKey(event) {
    var ctrl = event.modifiers & Qt.ControlModifier
    event.accepted = true

    if (confirmClear) {
      if (event.key === Qt.Key_Y) clearAll()
      else if (event.key === Qt.Key_N || event.key === Qt.Key_Escape) confirmClear = false
      return
    }

    switch (event.key) {
    case Qt.Key_Escape: close(); return
    case Qt.Key_Return: case Qt.Key_Enter: activate(); return
    case Qt.Key_Down: case Qt.Key_Tab: move(1); return
    case Qt.Key_Up: case Qt.Key_Backtab: move(-1); return
    case Qt.Key_PageDown: move(Math.min(rows.length - 1, 8)); return
    case Qt.Key_PageUp: move(-Math.min(rows.length - 1, 8)); return
    case Qt.Key_Home: selected = 0; return
    case Qt.Key_End: selected = Math.max(0, rows.length - 1); return
    case Qt.Key_Delete:
      if (ctrl) confirmClear = entries.length > 0
      else removeCurrent()
      return
    }
    if (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N)) { move(1); return }
    if (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P)) { move(-1); return }

    if (Util.editsFilter(event, filter)) {
      filter = Util.editedFilter(event, filter)
      selected = 0
      applyFilter()
      return
    }
    if (!ctrl && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier))
        && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
      filter += event.text
      selected = 0
      applyFilter()
      return
    }
    event.accepted = false
  }

  // ---------------------------------------------------------------- processes
  Process {
    id: copyProc
    onExited: if (root.pendingPaste) pasteTimer.restart()
  }

  // Ctrl+V must land after the overlay has released keyboard focus.
  Timer {
    id: pasteTimer
    interval: 80
    onTriggered: {
      root.pendingPaste = null
      Util.execArgv(["hyprctl", "dispatch", "sendshortcut", "CTRL,V,"])
    }
  }

  // Ensure the state files exist before the watcher is attached, and reap
  // watchers a previous shell instance may have left behind.
  // The bracketed pattern keeps pkill from matching this bash invocation itself.
  Process {
    id: initProc
    command: ["bash", "-c", 'mkdir -p "$0" && touch "$1"; pkill -f "$2" || true', root.itemsDir, root.historyPath, "wl-paste .*--watch .*/[c]lipboard/capture[.]sh"]
    onExited: {
      historyFile.path = root.historyPath
      textWatch.running = true
      imageWatch.running = true
    }
  }

  // pdeathsig makes the kernel kill the watchers with the shell.
  Process {
    id: textWatch
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", root.captureScript, "text"]
    environment: ({ CLIP_MAX_BYTES: String(Config.clipboard.maxTextBytes) })
    onExited: restartTimer.restart()
  }

  Process {
    id: imageWatch
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image/png", "--watch", root.captureScript, "image/png"]
    environment: ({ CLIP_MAX_BYTES: String(Config.clipboard.maxTextBytes) })
    onExited: restartTimer.restart()
  }

  Timer {
    id: restartTimer
    interval: 1000
    onTriggered: {
      if (!textWatch.running) textWatch.running = true
      if (!imageWatch.running) imageWatch.running = true
    }
  }

  FileView {
    id: historyFile
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadHistory(text())
    onLoadFailed: root.loadHistory("")
    onFileChanged: reload()
  }

  FileView {
    id: previewFile
    path: root.opened && root.current && root.current.type === "text" ? root.current.file : ""
    printErrors: false
  }

  Timer {
    interval: 30000
    running: root.opened
    repeat: true
    onTriggered: root.now = Date.now() / 1000
  }

  // ---------------------------------------------------------------- ui
  Overlay {
    id: overlay
    opened: root.opened
    namespace: "shell-clipboard"
    onDismissed: root.close()

    Item {
      id: keys
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(event) { root.handleKey(event) }
    }

    Card {
      id: card
      anchors.centerIn: parent
      width: Config.clipboard.width
      height: Config.clipboard.height

      Column {
        anchors.fill: parent

        SearchField {
          id: search
          width: parent.width
          text: root.filter
          placeholder: Config.clipboard.placeholder
        }

        Rectangle { width: parent.width; height: Theme.borderWidth; color: Theme.border }

        Item {
          width: parent.width
          height: card.height - search.height - footer.height - Theme.borderWidth * 2

          ListView {
            id: list
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.round(parent.width * 0.6)
            clip: true
            model: root.rows
            currentIndex: root.selected
            highlightMoveDuration: 0
            highlightFollowsCurrentItem: true
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
              required property var modelData
              required property int index
              width: list.width
              height: Config.clipboard.rowHeight
              color: index === root.selected ? Theme.selected : (rowMouse.containsMouse ? Theme.hover : "transparent")

              Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.space
                anchors.rightMargin: Theme.space
                spacing: Theme.space

                Item {
                  width: Config.clipboard.rowHeight - Theme.space * 2
                  height: width
                  anchors.verticalCenter: parent.verticalCenter

                  Image {
                    id: thumb
                    anchors.fill: parent
                    visible: modelData.type === "image"
                    source: modelData.type === "image" ? Util.fileUrl(modelData.file) : ""
                    sourceSize.width: 128
                    sourceSize.height: 128
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: modelData.type !== "image"
                    text: "󰅍"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontIcon
                  }
                }

                Column {
                  width: parent.width - parent.spacing - (Config.clipboard.rowHeight - Theme.space * 2)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Theme.spaceSm

                  Text {
                    width: parent.width
                    text: modelData.type === "image" ? modelData.text : root.firstLine(modelData.text)
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: root.relativeTime(modelData.time) + "  ·  " + root.formatBytes(modelData.bytes)
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                onEntered: if (root.hoverArmed) root.selected = index
                onPositionChanged: function(mouse) { if (root.hoverMoved(this, mouse)) root.selected = index }
                onClicked: { root.selected = index; root.activate() }
              }
            }

            Text {
              anchors.centerIn: parent
              visible: root.rows.length === 0
              text: root.entries.length === 0 ? "Clipboard history is empty" : "No matches"
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontBody
            }
          }

          Rectangle {
            anchors.left: list.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Theme.borderWidth
            color: Theme.border
          }

          Item {
            id: preview
            anchors.left: list.right
            anchors.leftMargin: Theme.borderWidth
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Image {
              anchors.fill: parent
              anchors.margins: Theme.space
              visible: root.current !== null && root.current.type === "image"
              source: visible ? Util.fileUrl(root.current.file) : ""
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              cache: false
            }

            Flickable {
              anchors.fill: parent
              anchors.margins: Theme.space
              visible: root.current !== null && root.current.type === "text"
              clip: true
              contentWidth: width
              contentHeight: previewText.height
              boundsBehavior: Flickable.StopAtBounds

              Text {
                id: previewText
                width: parent.width
                // Very large entries would stall layout; the file is still copied whole.
                text: Util.truncate(previewFile.text(), 20000)
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
              }
            }
          }
        }

        Rectangle { width: parent.width; height: Theme.borderWidth; color: Theme.border }

        Item {
          id: footer
          width: parent.width
          height: Theme.fontCaption + Theme.space * 2

          Text {
            anchors.fill: parent
            anchors.leftMargin: Theme.space
            anchors.rightMargin: Theme.space
            verticalAlignment: Text.AlignVCenter
            text: root.confirmClear
              ? "Clear all clipboard history?  Y to confirm · N to cancel"
              : "Enter copy" + (Config.clipboard.pasteOnSelect ? " + paste" : "") + "  ·  Del remove  ·  Ctrl+Del clear all  ·  " + root.rows.length + "/" + root.entries.length
            color: root.confirmClear ? Theme.urgent : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
