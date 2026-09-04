import QtQuick
import Quickshell.Io
import Quickshell.Networking
import qs.Commons
import qs.Ui

// Wi-Fi panel: radio toggle, wired state, network list with inline password
// entry for secured networks that NetworkManager does not know yet.
BarPopup {
  id: root

  property var wifi: null          // WifiDevice
  property var wired: null         // WiredDevice
  property var networks: []        // sorted WifiNetwork list, owned by the widget
  property var signalGlyph: function(v) { return "󰤨" }
  property var pending: null       // network waiting for a password
  property string status: ""
  readonly property int rowHeight: Theme.fontBody + Theme.space * 2
  readonly property int maxRows: 8
  readonly property bool radioOn: Networking.wifiEnabled

  // Keys: j/k or Ctrl+N/P move the cursor over the radio toggle, the
  // networks, Rescan and nmtui; Enter or Space acts on the row; r rescans.
  // The password box takes the keyboard while it is up; Escape there only
  // cancels the prompt.
  property int cursor: 0
  readonly property var listed: radioOn ? networks : []
  readonly property int rowCount: 1 + listed.length + 2
  readonly property int rescanRow: 1 + listed.length
  readonly property int nmtuiRow: rescanRow + 1
  function move(delta) { cursor = ((cursor + delta) % rowCount + rowCount) % rowCount }
  function doRescan() { status = ""; if (!rescan.running) rescan.running = true }
  function act() {
    if (cursor === 0) { if (wifi && Networking.wifiHardwareEnabled) Networking.wifiEnabled = !radioOn; return }
    if (cursor === rescanRow) { doRescan(); return }
    if (cursor === nmtuiRow) { dismiss(); Util.execArgv([Config.terminal, "-e", "nmtui"]); return }
    var net = listed[cursor - 1]
    if (net) activate(net)
  }

  function handleKey(event) {
    if (pending) return false          // the password field owns the keys
    var ctrl = event.modifiers & Qt.ControlModifier
    if (ctrl && event.key === Qt.Key_N) { move(1); return true }
    if (ctrl && event.key === Qt.Key_P) { move(-1); return true }
    if (ctrl) return false
    switch (event.key) {
    case Qt.Key_J: case Qt.Key_Down: move(1); return true
    case Qt.Key_K: case Qt.Key_Up: move(-1); return true
    case Qt.Key_R: doRescan(); return true
    case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: act(); return true
    }
    return false
  }
  onRowCountChanged: if (cursor >= rowCount) cursor = Math.max(0, rowCount - 1)
  // The password box took the keyboard; when it goes away nothing holds
  // focus and keys would fall on the floor, so take it back here. Key
  // events then bubble up to the card's handler as before.
  onPendingChanged: if (!pending && visible) forceActiveFocus()

  onVisibleChanged: {
    if (wifi) wifi.scannerEnabled = visible
    if (!visible) { pending = null; status = "" }
    else cursor = 0
  }

  function activate(net) {
    status = ""
    if (net.connected) { net.disconnect(); pending = null; return }
    if (net.known || net.security === WifiSecurityType.Open) { net.connect(); pending = null; return }
    pending = pending === net ? null : net
  }

  function submit(psk) {
    if (!pending || psk === "") return
    status = "Connecting to " + pending.name + "…"
    pending.connectWithPsk(psk)
    pending = null
  }

  function stateText(net) {
    if (net.stateChanging) return net.state === ConnectionState.Disconnecting ? "Disconnecting…" : "Connecting…"
    if (net.connected) return "Connected"
    return net.known ? "Saved" : ""
  }

  Process { id: rescan; command: ["nmcli", "device", "wifi", "rescan"] }

  Instantiator {
    model: root.networks
    Connections {
      required property var modelData
      target: modelData
      function onConnectionFailed(reason) {
        root.status = modelData.name + ": " + ConnectionFailReason.toString(reason)
      }
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
        text: "Wi-Fi"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        font.weight: Font.DemiBold
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: toggle.left
        anchors.rightMargin: Theme.space
        text: root.wifi === null ? "No adapter" : !Networking.wifiHardwareEnabled ? "Blocked" : root.radioOn ? "On" : "Off"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
      }
      PanelToggle {
        id: toggle
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceSm
        checked: root.radioOn
        enabled: root.wifi !== null && Networking.wifiHardwareEnabled
        onToggled: function(value) { Networking.wifiEnabled = value }
      }
    }

    Item {
      visible: root.wired !== null
      width: parent.width
      height: root.rowHeight
      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space
        Text { text: "󰈀"; color: Theme.foreground; font.family: Theme.fontFamily; font.pixelSize: Theme.fontIcon }
        Text {
          text: root.wired === null ? "" : root.wired.connected
            ? (root.wired.network ? root.wired.network.name : "Ethernet")
            : root.wired.hasLink ? "Ethernet — link, not connected" : "Ethernet — no link"
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontBody
        }
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.wired !== null && root.wired.connected
        text: "󰄬"
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontIcon
      }
    }

    PanelDivider {}

    Item {
      width: parent.width
      height: root.rowHeight
      PanelCaption { anchors.verticalCenter: parent.verticalCenter; text: "Networks" }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "󰑐 Rescan"
        color: rescanArea.containsMouse || root.cursor === root.rescanRow ? Theme.accent : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
        MouseArea {
          id: rescanArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.doRescan()
        }
      }
    }

    Text {
      visible: list.count === 0
      width: parent.width
      height: root.rowHeight
      verticalAlignment: Text.AlignVCenter
      text: root.radioOn ? "No networks found" : "Wi-Fi is off"
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }

    ListView {
      id: list
      width: parent.width
      height: Math.min(contentHeight, root.rowHeight * root.maxRows + (root.pending ? root.rowHeight : 0))
      clip: true
      interactive: contentHeight > height
      model: root.listed
      readonly property int cursorRow: root.cursor - 1
      onCursorRowChanged: if (cursorRow >= 0 && cursorRow < count) positionViewAtIndex(cursorRow, ListView.Contain)

      delegate: Column {
        id: row
        required property var modelData
        required property int index
        readonly property bool secured: modelData.security !== WifiSecurityType.Open
        readonly property bool asking: root.pending === modelData
        readonly property bool underCursor: root.cursor === index + 1
        width: list.width

        Rectangle {
          width: parent.width
          height: root.rowHeight
          radius: Theme.cornerRadius
          color: rowArea.containsMouse ? Theme.hover : row.asking ? Theme.selected : "transparent"
          border.width: row.underCursor ? Theme.borderWidth : 0
          border.color: Theme.accent

          Row {
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.space
            spacing: Theme.space
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.signalGlyph(row.modelData.signalStrength)
              color: row.modelData.connected ? Theme.accent : Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontIcon
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: list.width - Theme.space * 2 - 150
              elide: Text.ElideRight
              text: row.modelData.name
              color: row.modelData.connected ? Theme.accent : Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontBody
            }
          }

          Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.space
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.stateText(row.modelData)
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontCaption
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: row.secured
              text: "󰌾"
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontIcon
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: row.modelData.connected
              text: "󰄬"
              color: Theme.accent
              font.family: Theme.fontFamily
              font.pixelSize: Theme.fontIcon
            }
          }

          MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { root.cursor = row.index + 1; root.activate(row.modelData) }
          }
        }

        Rectangle {
          visible: row.asking
          width: parent.width
          height: root.rowHeight
          radius: Theme.cornerRadius
          color: Theme.background
          border.color: input.activeFocus ? Theme.accent : Theme.border
          border.width: Theme.borderWidth

          Text {
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.space
            visible: input.text === ""
            text: "Password, Enter to connect"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
          TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Theme.space
            anchors.rightMargin: Theme.space
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            color: Theme.foreground
            selectionColor: Theme.selected
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            onVisibleChanged: { text = ""; if (visible) forceActiveFocus() }
            Keys.onReturnPressed: root.submit(text)
            Keys.onEnterPressed: root.submit(text)
            Keys.onEscapePressed: root.pending = null
          }
        }
      }
    }

    Text {
      visible: root.status !== ""
      width: parent.width
      wrapMode: Text.Wrap
      text: root.status
      color: Theme.warning
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
    }

    PanelDivider {}

    PanelButton {
      icon: "󰖟"
      text: "Open nmtui"
      highlighted: root.cursor === root.nmtuiRow
      onClicked: { root.dismiss(); Util.execArgv([Config.terminal, "-e", "nmtui"]) }
    }
  }
}
