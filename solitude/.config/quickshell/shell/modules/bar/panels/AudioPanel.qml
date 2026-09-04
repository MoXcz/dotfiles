import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

// Audio panel: every PipeWire sink and source with a volume slider and mute
// toggle; clicking a row makes it the default. The footer opens whichever
// mixer is installed (wiremix in the terminal, else pavucontrol).
//
// Keys: j/k or Ctrl+N/P move the cursor, Enter makes the device default,
// h/l change its volume by 5%, m mutes. Tab or Escape close.
BarPopup {
  id: root

  property var sinks: []
  property var sources: []
  property string mixer: ""
  readonly property int rowHeight: Theme.fontBody + Theme.space * 2
  readonly property int maxRows: 5

  // Cursor over the rows in order: sinks, sources, then the mixer button.
  property int cursor: 0
  readonly property int rowCount: sinks.length + sources.length + (mixer !== "" ? 1 : 0)
  function nodeAt(i) {
    if (i < sinks.length) return sinks[i]
    i -= sinks.length
    return i < sources.length ? sources[i] : null
  }
  function move(delta) {
    if (rowCount === 0) return
    cursor = ((cursor + delta) % rowCount + rowCount) % rowCount
  }
  function nudge(delta) {
    var n = nodeAt(cursor)
    if (n && n.audio) n.audio.volume = Util.clamp(n.audio.volume + delta, 0, 1)
  }

  function handleKey(event) {
    var ctrl = event.modifiers & Qt.ControlModifier
    if (ctrl && event.key === Qt.Key_N) { move(1); return true }
    if (ctrl && event.key === Qt.Key_P) { move(-1); return true }
    if (ctrl) return false
    switch (event.key) {
    case Qt.Key_J: case Qt.Key_Down: move(1); return true
    case Qt.Key_K: case Qt.Key_Up: move(-1); return true
    case Qt.Key_L: case Qt.Key_Right: nudge(0.05); return true
    case Qt.Key_H: case Qt.Key_Left: nudge(-0.05); return true
    case Qt.Key_M: { var n = nodeAt(cursor); if (n && n.audio) n.audio.muted = !n.audio.muted; return true }
    case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: {
      var target = nodeAt(cursor)
      if (target) select(target); else openMixer()
      return true
    }
    }
    return false
  }

  function refresh() {
    var all = Pipewire.nodes.values.filter(function(n) { return n.audio !== null && !n.isStream })
    all.sort(function(a, b) { return label(a).localeCompare(label(b)) })
    sinks = all.filter(function(n) { return n.isSink })
    sources = all.filter(function(n) { return !n.isSink })
  }

  function label(node) { return node.nickname || node.description || node.name }

  function isDefault(node) {
    return node.isSink ? Pipewire.defaultAudioSink === node : Pipewire.defaultAudioSource === node
  }

  function select(node) {
    if (node.isSink) Pipewire.preferredDefaultAudioSink = node
    else Pipewire.preferredDefaultAudioSource = node
  }

  function openMixer() {
    dismiss()
    if (mixer === "wiremix") Util.execArgv([Config.terminal, "-e", "wiremix"])
    else if (mixer === "pavucontrol") Util.execArgv(["pavucontrol"])
  }

  onVisibleChanged: if (visible) { refresh(); cursor = 0 }
  Connections {
    target: Pipewire.nodes
    function onValuesChanged() { root.refresh() }
  }
  Component.onCompleted: refresh()

  // Volume and mute are only readable while the nodes are bound.
  PwObjectTracker { objects: root.visible ? root.sinks.concat(root.sources) : [] }

  Process {
    command: ["sh", "-c", "command -v wiremix >/dev/null && echo wiremix || { command -v pavucontrol >/dev/null && echo pavucontrol; }"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.mixer = text.trim() }
  }

  component NodeList: Column {
    id: section
    property string title: ""
    property string emptyText: ""
    property var nodes: []
    property int offset: 0          // cursor index of this section's first row
    width: parent.width
    spacing: Theme.spaceSm

    PanelCaption { text: section.title }

    Text {
      visible: section.nodes.length === 0
      height: root.rowHeight
      verticalAlignment: Text.AlignVCenter
      text: section.emptyText
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }

    ListView {
      id: list
      width: parent.width
      height: Math.min(contentHeight, (root.rowHeight * 2 + Theme.spaceSm) * root.maxRows)
      clip: true
      interactive: contentHeight > height
      model: section.nodes
      spacing: Theme.spaceSm
      // Keep the cursor's row in view.
      readonly property int cursorRow: root.cursor - section.offset
      onCursorRowChanged: if (cursorRow >= 0 && cursorRow < count) positionViewAtIndex(cursorRow, ListView.Contain)

      delegate: Rectangle {
        id: row
        required property var modelData
        required property int index
        readonly property bool active: root.isDefault(modelData)
        readonly property bool underCursor: root.cursor === section.offset + index
        readonly property var audio: modelData.audio
        readonly property bool muted: audio !== null && audio.muted
        readonly property real volume: audio !== null ? audio.volume : 0
        width: list.width
        height: root.rowHeight * 2
        radius: Theme.cornerRadius
        color: active ? Theme.selected : rowArea.containsMouse ? Theme.hover : "transparent"
        border.width: underCursor ? Theme.borderWidth : 0
        border.color: Theme.accent

        MouseArea {
          id: rowArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: { root.cursor = section.offset + row.index; root.select(row.modelData) }
        }

        Item {
          x: Theme.space
          width: parent.width - Theme.space * 2
          height: root.rowHeight

          Text {
            id: muteBtn
            anchors.verticalCenter: parent.verticalCenter
            text: row.muted ? "󰝟" : row.modelData.isSink ? "󰕾" : "󰍬"
            color: row.muted ? Theme.muted : muteArea.containsMouse ? Theme.foreground : Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontIcon
            MouseArea {
              id: muteArea
              anchors.fill: parent
              anchors.margins: -Theme.spaceSm
              hoverEnabled: true
              onClicked: if (row.audio) row.audio.muted = !row.audio.muted
            }
          }
          Text {
            anchors.left: muteBtn.right
            anchors.leftMargin: Theme.space
            anchors.right: trailing.left
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.label(row.modelData)
            color: row.active ? Theme.accent : Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
          Row {
            id: trailing
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Math.round(row.volume * 100) + "%"
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontCaption
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: row.active
              text: "󰄬"
              color: Theme.accent
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontIcon
            }
          }
        }

        PanelSlider {
          x: Theme.space
          y: root.rowHeight
          width: parent.width - Theme.space * 2
          height: root.rowHeight
          value: row.volume
          dim: row.muted
          onMoved: function(v) { if (row.audio) row.audio.volume = v }
        }
      }
    }
  }

  Column {
    width: parent.width
    spacing: Theme.space

    Text {
      text: "Audio"
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
      font.weight: Font.DemiBold
    }

    NodeList { title: "Output"; emptyText: "No output devices"; nodes: root.sinks; offset: 0 }

    PanelDivider {}

    NodeList { title: "Input"; emptyText: "No input devices"; nodes: root.sources; offset: root.sinks.length }

    PanelDivider { visible: root.mixer !== "" }

    PanelButton {
      visible: root.mixer !== ""
      icon: "󰕬"
      text: "Open mixer"
      highlighted: root.cursor === root.rowCount - 1
      onClicked: root.openMixer()
    }
  }
}
