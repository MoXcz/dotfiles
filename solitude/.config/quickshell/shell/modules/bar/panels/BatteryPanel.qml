import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui

// Battery details from UPower plus the power-profiles-daemon profile picker.
// The profile section only shows when powerprofilesctl exists on this box.
BarPopup {
  id: root

  property var device: null
  readonly property bool present: device !== null && device.ready && device.isPresent
  readonly property int percent: present ? Math.round(device.percentage * 100) : 0
  readonly property bool charging: present
    && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
  readonly property int rowHeight: Theme.fontBody + Theme.space * 2

  property bool profilesAvailable: false
  property string activeProfile: ""
  readonly property var profiles: [
    { name: "performance", label: "Performance", icon: "󰓅" },
    { name: "balanced", label: "Balanced", icon: "󰾅" },
    { name: "power-saver", label: "Power saver", icon: "󰾆" }
  ]

  function formatDuration(seconds) {
    var s = Math.round(Number(seconds) || 0)
    if (s <= 0) return "—"
    var h = Math.floor(s / 3600)
    var m = Math.round((s % 3600) / 60)
    return h > 0 ? h + "h " + m + "m" : m + "m"
  }

  function stateText() {
    if (!present) return "No battery"
    return UPowerDeviceState.toString(device.state)
  }

  function timeText() {
    if (!present) return "—"
    if (charging) return device.timeToFull > 0 ? formatDuration(device.timeToFull) + " to full" : "—"
    if (device.state === UPowerDeviceState.FullyCharged) return "Full"
    return device.timeToEmpty > 0 ? formatDuration(device.timeToEmpty) + " left" : "—"
  }

  function rateText() {
    if (!present) return "—"
    var w = Math.abs(Number(device.changeRate) || 0)
    return w > 0 ? w.toFixed(1) + " W" : "—"
  }

  function energyText() {
    if (!present || !(device.energyCapacity > 0)) return "—"
    return device.energy.toFixed(1) + " / " + device.energyCapacity.toFixed(1) + " Wh"
  }

  function setProfile(name) {
    if (setProc.running || name === activeProfile) return
    setProc.target = name
    setProc.running = true
  }

  onVisibleChanged: if (visible && profilesAvailable) getProc.running = true

  Process {
    id: probe
    command: ["sh", "-c", "command -v powerprofilesctl >/dev/null"]
    running: true
    onExited: function(exitCode, exitStatus) {
      root.profilesAvailable = exitCode === 0
      if (root.profilesAvailable) getProc.running = true
    }
  }

  Process {
    id: getProc
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector { onStreamFinished: root.activeProfile = text.trim() }
  }

  Process {
    id: setProc
    property string target: ""
    command: ["powerprofilesctl", "set", target]
    onExited: function(exitCode, exitStatus) { getProc.running = true }
  }

  component InfoRow: Item {
    property string label: ""
    property string value: ""
    width: parent.width
    height: Theme.fontBody + Theme.space
    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: label
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }
    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: value
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }
  }

  Column {
    width: parent.width
    spacing: Theme.spaceSm

    Item {
      width: parent.width
      height: Theme.fontHeading + Theme.space
      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "Battery"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        font.weight: Font.DemiBold
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.present ? root.percent + "%" : "—"
        color: root.present && !root.charging && root.percent < 15 ? Theme.urgent : Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontHeading
      }
    }

    Rectangle {
      width: parent.width
      height: Theme.spaceSm
      radius: height / 2
      color: Theme.surfaceAlt
      Rectangle {
        width: parent.width * root.percent / 100
        height: parent.height
        radius: parent.radius
        color: root.charging ? Theme.success : root.percent < 15 ? Theme.urgent : Theme.accent
      }
    }

    InfoRow { label: "State"; value: root.stateText() }
    InfoRow { label: "Time"; value: root.timeText() }
    InfoRow { label: "Power draw"; value: root.rateText() }
    InfoRow { label: "Energy"; value: root.energyText() }
    InfoRow {
      visible: root.present && root.device.healthSupported
      label: "Health"
      value: root.present ? Math.round(root.device.healthPercentage) + "%" : "—"
    }

    Rectangle {
      visible: root.profilesAvailable
      width: parent.width
      height: Theme.borderWidth
      color: Theme.border
    }

    Text {
      visible: root.profilesAvailable
      text: "Power profile"
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontCaption
    }

    Repeater {
      model: root.profilesAvailable ? root.profiles : []

      Rectangle {
        id: profileRow
        required property var modelData
        readonly property bool active: modelData.name === root.activeProfile
        width: parent.width
        height: root.rowHeight
        radius: Theme.cornerRadius
        color: active ? Theme.selected : profileArea.containsMouse ? Theme.hover : "transparent"

        Row {
          anchors.verticalCenter: parent.verticalCenter
          x: Theme.space
          spacing: Theme.space
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: profileRow.modelData.icon
            color: profileRow.active ? Theme.accent : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontIcon
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: profileRow.modelData.label
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
          }
        }

        Text {
          visible: profileRow.active
          anchors.right: parent.right
          anchors.rightMargin: Theme.space
          anchors.verticalCenter: parent.verticalCenter
          text: "󰄬"
          color: Theme.accent
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontIcon
        }

        MouseArea {
          id: profileArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.setProfile(profileRow.modelData.name)
        }
      }
    }
  }
}
