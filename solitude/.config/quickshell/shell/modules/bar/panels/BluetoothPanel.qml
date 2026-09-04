import QtQuick
import Quickshell.Bluetooth
import qs.Commons
import qs.Ui

// Bluetooth panel: adapter power, discovery toggle, and the device list.
// Click a row to connect / disconnect (pairing first when needed); the
// small cross on a paired row forgets it.
//
// Keys: j/k or Ctrl+N/P move the cursor over the power toggle, Scan and
// the devices; Enter or Space acts on the row; s toggles scanning; x
// forgets the paired device under the cursor. Tab or Escape close.
BarPopup {
  id: root

  property var adapter: null       // BluetoothAdapter
  property var devices: []         // sorted BluetoothDevice list, owned by the widget
  property var pendingConnect: null // device to connect once pairing lands
  readonly property int rowHeight: Theme.fontBody + Theme.space * 2
  readonly property int maxRows: 8
  readonly property bool on: adapter !== null && adapter.enabled
  readonly property bool scanning: adapter !== null && adapter.discovering

  // Cursor rows: 0 power toggle, 1 scan, then the devices.
  property int cursor: 0
  readonly property var listed: on ? devices : []
  readonly property int rowCount: 2 + listed.length
  function move(delta) { cursor = ((cursor + delta) % rowCount + rowCount) % rowCount }
  function toggleScan() { if (adapter) adapter.discovering = !adapter.discovering }
  function deviceAt(i) { return i >= 2 ? (listed[i - 2] || null) : null }
  function act() {
    if (cursor === 0) { if (adapter && adapter.state !== BluetoothAdapterState.Blocked) adapter.enabled = !on; return }
    if (cursor === 1) { toggleScan(); return }
    var dev = deviceAt(cursor)
    if (dev) activate(dev)
  }

  function handleKey(event) {
    var ctrl = event.modifiers & Qt.ControlModifier
    if (ctrl && event.key === Qt.Key_N) { move(1); return true }
    if (ctrl && event.key === Qt.Key_P) { move(-1); return true }
    if (ctrl) return false
    switch (event.key) {
    case Qt.Key_J: case Qt.Key_Down: move(1); return true
    case Qt.Key_K: case Qt.Key_Up: move(-1); return true
    case Qt.Key_S: toggleScan(); return true
    case Qt.Key_X: { var dev = deviceAt(cursor); if (dev && dev.paired) dev.forget(); return true }
    case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: act(); return true
    }
    return false
  }
  onRowCountChanged: if (cursor >= rowCount) cursor = Math.max(0, rowCount - 1)

  readonly property var glyphs: ({
    "audio-headset": "󰋋", "audio-headphones": "󰋋", "audio-card": "󰓃",
    "input-mouse": "󰍽", "input-keyboard": "󰌌", "input-gaming": "󰊴",
    "input-tablet": "󰓶", "phone": "󰏲", "computer": "󰇅", "video-display": "󰍹"
  })

  onVisibleChanged: {
    if (!visible && adapter && adapter.discovering) adapter.discovering = false
    if (!visible) pendingConnect = null
    else cursor = 0
  }

  function glyph(dev) { return glyphs[dev.icon] || "󰂯" }

  function activate(dev) {
    if (dev.connected) { dev.disconnect(); return }
    if (dev.pairing) return
    if (dev.paired) { dev.connect(); return }
    pendingConnect = dev
    dev.trusted = true
    dev.pair()
  }

  function paired(dev) {
    if (dev === pendingConnect && dev.paired) { pendingConnect = null; dev.connect() }
  }

  function stateText(dev) {
    if (dev.pairing) return "Pairing…"
    if (dev.state === BluetoothDeviceState.Connecting) return "Connecting…"
    if (dev.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
    if (dev.connected) return "Connected"
    return dev.paired ? "Paired" : ""
  }

  function adapterText() {
    if (adapter === null) return "No adapter"
    if (adapter.state === BluetoothAdapterState.Blocked) return "Blocked"
    if (adapter.state === BluetoothAdapterState.Enabling) return "Turning on…"
    if (adapter.state === BluetoothAdapterState.Disabling) return "Turning off…"
    return on ? "On" : "Off"
  }

  Instantiator {
    model: root.devices
    Connections {
      required property var modelData
      target: modelData
      function onPairedChanged() { root.paired(modelData) }
    }
  }

  Column {
    width: parent.width
    spacing: Theme.spaceSm

    Rectangle {
      width: parent.width
      height: root.rowHeight
      radius: Theme.cornerRadius
      color: "transparent"
      border.width: root.cursor === 0 ? Theme.borderWidth : 0
      border.color: Theme.accent
      Text {
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.spaceSm
        text: "Bluetooth"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        font.weight: Font.DemiBold
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: toggle.left
        anchors.rightMargin: Theme.space
        text: root.adapterText()
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
      }
      PanelToggle {
        id: toggle
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceSm
        checked: root.on
        enabled: root.adapter !== null && root.adapter.state !== BluetoothAdapterState.Blocked
        onToggled: function(value) { if (root.adapter) root.adapter.enabled = value }
      }
    }

    PanelDivider {}

    Item {
      width: parent.width
      height: root.rowHeight
      PanelCaption { anchors.verticalCenter: parent.verticalCenter; text: "Devices" }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.on
        text: root.scanning ? "󰐥 Stop scan" : "󰑐 Scan"
        color: root.scanning || root.cursor === 1 ? Theme.accent : scanArea.containsMouse ? Theme.foreground : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
        MouseArea {
          id: scanArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.toggleScan()
        }
      }
    }

    Text {
      visible: list.count === 0
      width: parent.width
      height: root.rowHeight
      verticalAlignment: Text.AlignVCenter
      text: !root.on ? "Bluetooth is off" : root.scanning ? "Scanning…" : "No devices, scan to find some"
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }

    ListView {
      id: list
      width: parent.width
      height: Math.min(contentHeight, root.rowHeight * root.maxRows)
      clip: true
      interactive: contentHeight > height
      model: root.listed
      readonly property int cursorRow: root.cursor - 2
      onCursorRowChanged: if (cursorRow >= 0 && cursorRow < count) positionViewAtIndex(cursorRow, ListView.Contain)

      delegate: Rectangle {
        id: row
        required property var modelData
        required property int index
        readonly property bool underCursor: root.cursor === index + 2
        width: list.width
        height: root.rowHeight
        radius: Theme.cornerRadius
        color: rowArea.containsMouse ? Theme.hover : "transparent"
        border.width: underCursor ? Theme.borderWidth : 0
        border.color: Theme.accent

        Row {
          anchors.verticalCenter: parent.verticalCenter
          x: Theme.space
          spacing: Theme.space
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph(row.modelData)
            color: row.modelData.connected ? Theme.accent : Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontIcon
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: list.width - Theme.space * 2 - trailing.width - Theme.space * 3
            elide: Text.ElideRight
            text: row.modelData.name
            color: row.modelData.connected ? Theme.accent : Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
        }

        Row {
          id: trailing
          anchors.right: parent.right
          anchors.rightMargin: Theme.space
          anchors.verticalCenter: parent.verticalCenter
          spacing: Theme.space
          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.modelData.batteryAvailable
            text: "󰁹 " + Math.round(row.modelData.battery * 100) + "%"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.stateText(row.modelData)
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.modelData.connected
            text: "󰄬"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontIcon
          }
          // Forget: only for paired devices, dim until hovered.
          Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.modelData.paired
            text: "󰅖"
            color: forgetArea.containsMouse ? Theme.urgent : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontIcon
            MouseArea {
              id: forgetArea
              anchors.fill: parent
              anchors.margins: -Theme.spaceSm
              hoverEnabled: true
              onClicked: row.modelData.forget()
            }
          }
        }

        MouseArea {
          id: rowArea
          anchors.fill: parent
          anchors.rightMargin: row.modelData.paired ? Theme.fontIcon + Theme.space * 2 : 0
          hoverEnabled: true
          onClicked: { root.cursor = row.index + 2; root.activate(row.modelData) }
        }
      }
    }
  }
}
