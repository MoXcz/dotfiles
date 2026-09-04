import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// VPN panel: one switch for the tunnel, the tunnel's addresses while up,
// the last error from vpn, and the other configured connections.
BarPopup {
  id: root

  property var widget: null           // Vpn widget, owns the state
  property var connections: []        // names from `vpn list`
  readonly property int rowHeight: Theme.fontBody + Theme.space * 2
  readonly property bool usable: widget && widget.state !== "unavailable" && widget.state !== "nosudo"

  onVisibleChanged: if (visible && usable && !lister.running) lister.running = true

  function stateText() {
    if (!widget) return ""
    switch (widget.state) {
      case "up": return "Connected"
      case "connecting": return "Connecting…"
      case "off": return "Daemon stopped"
      case "unavailable": return "swanctl not installed"
      case "nosudo": return "Run: vpn setup"
    }
    return widget.busy ? "Working…" : "Disconnected"
  }

  Process {
    id: lister
    command: ["vpn", "list"]
    stdout: StdioCollector {
      onStreamFinished: root.connections = text.trim().split("\n").filter(function(n) { return n !== "" })
    }
  }

  Column {
    width: parent.width
    spacing: Theme.spaceSm

    Item {
      width: parent.width
      height: root.rowHeight
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "VPN"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        font.weight: Font.DemiBold
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: toggle.left
        anchors.rightMargin: Theme.space
        text: root.stateText()
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
      }
      PanelToggle {
        id: toggle
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        checked: root.widget ? (root.widget.up || root.widget.connecting) : false
        enabled: root.usable && root.widget && !root.widget.busy
        onToggled: function(value) { if (root.widget) value ? root.widget.connect() : root.widget.disconnect() }
      }
    }

    // Addresses, only meaningful while the tunnel is up.
    Column {
      visible: root.widget && root.widget.up
      width: parent.width
      spacing: 0
      Repeater {
        model: [
          { key: "Connection", value: root.widget ? root.widget.connection : "" },
          { key: "Tunnel IP", value: root.widget ? root.widget.virtualIp : "" },
          { key: "Gateway", value: root.widget ? root.widget.remote : "" }
        ]
        Item {
          required property var modelData
          width: parent.width
          height: root.rowHeight
          visible: modelData.value !== ""
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.key
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            text: modelData.value
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
        }
      }
    }

    Text {
      visible: root.widget && root.widget.error !== ""
      width: parent.width
      wrapMode: Text.Wrap
      text: root.widget ? root.widget.error : ""
      color: Theme.warning
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
    }

    PanelDivider { visible: root.connections.length > 1 }

    // Other connections: shown only when there is a choice to make. Clicking
    // one switches the widget's target and brings it up.
    Column {
      visible: root.connections.length > 1
      width: parent.width
      spacing: 0
      Item {
        width: parent.width
        height: root.rowHeight
        PanelCaption { anchors.verticalCenter: parent.verticalCenter; text: "Connections" }
      }
      Repeater {
        model: root.connections
        Rectangle {
          id: row
          required property string modelData
          readonly property bool active: root.widget && root.widget.connection === modelData && root.widget.up
          width: parent.width
          height: root.rowHeight
          radius: Theme.cornerRadius
          color: rowArea.containsMouse ? Theme.hover : "transparent"
          Text {
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.space
            text: row.modelData
            color: row.active ? Theme.accent : Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Theme.space
            visible: row.active
            text: "󰄬"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontIcon
          }
          MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              if (!root.widget || root.widget.busy) return
              if (row.active) { root.widget.disconnect(); return }
              root.widget.run("up", row.modelData)
            }
          }
        }
      }
    }

    PanelDivider {}

    PanelButton {
      icon: "󰆍"
      text: "Follow strongswan log"
      onClicked: { root.dismiss(); Util.execArgv([Config.terminal, "-e", "journalctl", "-fu", "strongswan"]) }
    }
  }
}
