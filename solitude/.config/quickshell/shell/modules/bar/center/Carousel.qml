import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import "../../menu/Routes.js" as Routes

// Horizontal picker for the center panel: preview tiles slide past a fixed
// center slot, the centered one drawn full size and the rest shrunk and
// dimmed. Rows come from a generator command in the menu's line format
// (glyph, title, payload, subtitle, image); Enter or a click on the centered
// tile runs the route's `run` argv with the payload.
Item {
  id: root

  property var route: null          // Routes.js node with generator + run
  property var rows: []
  property string status: ""
  readonly property int tileWidth: Config.center.tileWidth
  readonly property int tileHeight: Config.center.tileHeight
  readonly property int spacing: Theme.space

  implicitHeight: tileHeight + Theme.spaceLg + caption.implicitHeight + Theme.space

  function load() {
    rows = []
    status = route && route.loading ? route.loading : "Loading…"
    if (generator.running) generator.running = false
    generator.command = route ? route.generator : ["true"]
    generator.running = true
  }

  function activate() {
    var row = rows[list.currentIndex]
    if (!row || !row.argv) return
    Util.execArgv(row.argv)
    activated()
  }
  signal activated()

  function handleKey(event) {
    var ctrl = event.modifiers & Qt.ControlModifier
    // Ctrl+P / Ctrl+N step like h / l.
    if (ctrl && event.key === Qt.Key_P) { list.decrementCurrentIndex(); return true }
    if (ctrl && event.key === Qt.Key_N) { list.incrementCurrentIndex(); return true }
    switch (event.key) {
    case Qt.Key_Left: case Qt.Key_H: case Qt.Key_K: list.decrementCurrentIndex(); return true
    case Qt.Key_Right: case Qt.Key_L: case Qt.Key_J: list.incrementCurrentIndex(); return true
    case Qt.Key_Home: list.currentIndex = 0; return true
    case Qt.Key_End: list.currentIndex = Math.max(0, rows.length - 1); return true
    case Qt.Key_Return: case Qt.Key_Enter: activate(); return true
    }
    return false
  }

  Process {
    id: generator
    stdout: StdioCollector {
      onStreamFinished: {
        root.rows = Routes.parseRows(text, root.route || {})
        root.status = root.rows.length > 0 ? "" : "Nothing to show"
        // Start on the active entry when the generator marks one.
        for (var i = 0; i < root.rows.length; i++) {
          if (String(root.rows[i].subtitle).toLowerCase() === "active") { list.currentIndex = i; return }
        }
        list.currentIndex = 0
      }
    }
  }

  Text {
    anchors.centerIn: parent
    visible: root.rows.length === 0
    text: root.status
    color: Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
  }

  ListView {
    id: list
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: root.tileHeight + Theme.spaceLg
    orientation: ListView.Horizontal
    model: root.rows
    spacing: root.spacing
    clip: true
    // The current tile is always parked in the middle; scrolling moves the
    // strip, not the slot.
    preferredHighlightBegin: Math.round((width - root.tileWidth) / 2)
    preferredHighlightEnd: preferredHighlightBegin + root.tileWidth
    highlightRangeMode: ListView.StrictlyEnforceRange
    highlightMoveDuration: 220
    snapMode: ListView.SnapOneItem
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationWraps: false

    delegate: Item {
      id: tile
      required property int index
      required property var modelData
      readonly property bool current: index === list.currentIndex
      // 0 at the slot, 1 a full tile away; drives the shrink and dim.
      readonly property real away: Math.min(1, Math.abs((x + width / 2) - (list.contentX + list.width / 2)) / (root.tileWidth + root.spacing))
      width: root.tileWidth
      height: list.height

      // ClippingRectangle rounds the preview itself; a plain clip would
      // leave square image corners poking past the rounded border.
      ClippingRectangle {
        anchors.centerIn: parent
        width: root.tileWidth
        height: root.tileHeight
        radius: Theme.cornerRadius * 2
        color: Theme.surfaceAlt
        border.width: tile.current ? 2 : Theme.borderWidth
        border.color: tile.current ? Theme.accent : Theme.border
        scale: 1 - tile.away * 0.18
        opacity: 1 - tile.away * 0.5

        Image {
          id: preview
          anchors.fill: parent
          visible: !!tile.modelData.image && status === Image.Ready
          source: tile.modelData.image ? Util.fileUrl(tile.modelData.image) : ""
          sourceSize.width: root.tileWidth * 2
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
        }

        Text {
          anchors.centerIn: parent
          visible: !preview.visible
          text: tile.modelData.glyph || ""
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontDisplay
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: { if (tile.current) root.activate(); else list.currentIndex = tile.index }
      }
    }

    MouseArea {
      anchors.fill: parent
      z: -1
      onWheel: function(event) {
        if (event.angleDelta.y < 0 || event.angleDelta.x < 0) list.incrementCurrentIndex()
        else list.decrementCurrentIndex()
      }
    }
  }

  // Title and subtitle of whatever sits in the slot.
  Column {
    id: caption
    anchors.top: list.bottom
    anchors.topMargin: Theme.space
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 2
    readonly property var row: root.rows[list.currentIndex] || null

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: caption.row ? caption.row.title : ""
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
      font.weight: Font.DemiBold
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: text.length > 0
      text: caption.row ? String(caption.row.subtitle || "") : ""
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
    }
  }
}
