import QtQuick
import qs.Commons
import qs.Ui

// Windows VM panel: one switch for the VM, its state, the last error from
// windows-vm, and shortcuts to RDP, the web console and the logs.
BarPopup {
  id: root

  property var widget: null           // Windows widget, owns the state
  readonly property int rowHeight: Theme.fontBody + Theme.space * 2
  readonly property bool usable: widget && widget.state !== "unavailable"

  function stateText() {
    if (!widget) return ""
    if (widget.busy) return "Working…"
    switch (widget.state) {
      case "up": return "Running"
      case "booting": return "Booting…"
      case "unavailable": return "Run: windows-vm install"
    }
    return "Stopped"
  }

  Column {
    width: parent.width
    spacing: Theme.spaceSm

    Item {
      width: parent.width
      height: root.rowHeight
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Windows VM"
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
        checked: root.widget ? root.widget.running : false
        enabled: root.usable && root.widget && !root.widget.busy
        onToggled: function(value) { if (root.widget) value ? root.widget.start() : root.widget.stop() }
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

    PanelDivider { visible: root.usable }

    PanelButton {
      visible: root.usable
      enabled: root.widget && root.widget.up
      opacity: enabled ? 1 : 0.4
      icon: "󰢹"
      text: "Connect with RDP"
      onClicked: { root.dismiss(); root.widget.connect() }
    }

    PanelButton {
      visible: root.usable
      enabled: root.widget && root.widget.running
      opacity: enabled ? 1 : 0.4
      icon: "󰖟"
      text: "Open web console"
      onClicked: { root.dismiss(); root.widget.console_() }
    }

    PanelButton {
      visible: root.usable
      icon: "󰆍"
      text: "Follow VM log"
      onClicked: { root.dismiss(); Util.execArgv([Config.terminal, "-e", "docker", "logs", "-f", "windows"]) }
    }
  }
}
