import QtQuick
import qs.Commons
import qs.Ui

// Resource breakdown fed by SystemStats: CPU, memory, GPU (when one is
// visible to the shell) and mounted disks, each as a label row over a thin
// usage bar, with the sensor temperature next to the percentage where one is
// known, and the top processes under CPU and memory. Footer opens btop in
// the configured terminal when installed; it is the only actionable row, so
// the cursor rests on it and Enter opens btop straight away.
BarPopup {
  id: root

  property var stats: null
  readonly property int rowHeight: Theme.fontBody + Theme.space
  readonly property int procRowHeight: Theme.fontCaption + Theme.spaceSm * 2

  function openBtop() { dismiss(); Util.execArgv([Config.terminal, "-e", "btop"]) }
  function handleKey(event) {
    if (event.modifiers & Qt.ControlModifier) return false
    switch (event.key) {
    case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
      if (stats && stats.btopAvailable) openBtop()
      return true
    }
    return false
  }

  function pct(v) { return Math.round(Number(v) || 0) + "%" }
  function gibText(used, total) { return Number(used).toFixed(1) + " / " + Number(total).toFixed(1) + " GiB" }
  // "42%  ·  65°C" when a sensor is known, "42%" otherwise.
  function pctTemp(v, t) { return pct(v) + (t >= 0 ? "  ·  " + t + "°C" : "") }

  // The disk list only refreshes on a slow cadence unless the panel is up.
  onVisibleChanged: if (stats) stats.detailed = visible

  function levelColor(percent) {
    if (percent > 95) return Theme.urgent
    if (percent > 80) return Theme.warning
    return Theme.accent
  }

  // Compact "name ........ value" lines for the process tables.
  component ProcList: Column {
    id: procs
    property var rows: []
    property string unit: ""
    width: parent.width
    spacing: 0
    Repeater {
      model: procs.rows
      Item {
        required property var modelData
        width: procs.width
        height: root.procRowHeight
        Text {
          anchors.left: parent.left
          anchors.leftMargin: Theme.space
          anchors.right: value.left
          anchors.rightMargin: Theme.space
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.name
          color: Theme.muted
          elide: Text.ElideRight
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontCaption
        }
        Text {
          id: value
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.value + procs.unit
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontCaption
        }
      }
    }
  }

  // "Label ........ value" row with a usage bar beneath.
  component StatRow: Column {
    id: statRow
    property string label: ""
    property string value: ""
    property real percent: 0
    width: parent.width
    spacing: Theme.spaceSm

    Item {
      width: parent.width
      height: root.rowHeight
      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: statRow.label
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: statRow.value
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
      }
    }

    Rectangle {
      width: parent.width
      height: 4
      radius: 2
      color: Theme.surfaceAlt
      Rectangle {
        width: Math.round(parent.width * Util.clamp(statRow.percent / 100, 0, 1))
        height: parent.height
        radius: parent.radius
        color: root.levelColor(statRow.percent)
        Behavior on width { NumberAnimation { duration: 250 } }
      }
    }
  }

  Column {
    width: parent.width
    spacing: Theme.space

    PanelCaption { text: "CPU" }
    StatRow {
      label: "Usage"
      value: root.stats ? root.pctTemp(root.stats.cpu, root.stats.cpuTemp) : "—"
      percent: root.stats ? root.stats.cpu : 0
    }
    ProcList { rows: root.stats ? root.stats.topCpu : []; unit: "%" }

    PanelDivider {}

    PanelCaption { text: "Memory" }
    StatRow {
      label: "RAM"
      value: root.stats ? root.pct(root.stats.memPercent) + "  " + root.gibText(root.stats.memUsedGiB, root.stats.memTotalGiB) : "—"
      percent: root.stats ? root.stats.memPercent : 0
    }
    StatRow {
      visible: root.stats && root.stats.swapTotalGiB > 0
      label: "Swap"
      value: root.stats ? root.pct(root.stats.swapPercent) + "  " + root.gibText(root.stats.swapUsedGiB, root.stats.swapTotalGiB) : "—"
      percent: root.stats ? root.stats.swapPercent : 0
    }
    ProcList { rows: root.stats ? root.stats.topMem : []; unit: " MiB" }

    PanelDivider { visible: root.stats && root.stats.gpuAvailable }

    PanelCaption { visible: root.stats && root.stats.gpuAvailable; text: "GPU" }
    StatRow {
      visible: root.stats && root.stats.gpuAvailable
      label: "Usage"
      value: root.stats ? root.pctTemp(root.stats.gpuUtil, root.stats.gpuTemp) : "—"
      percent: root.stats ? root.stats.gpuUtil : 0
    }
    StatRow {
      visible: root.stats && root.stats.gpuAvailable && root.stats.gpuMemTotalGiB > 0
      label: "VRAM"
      value: root.stats ? root.gibText(root.stats.gpuMemUsedGiB, root.stats.gpuMemTotalGiB) : "—"
      percent: root.stats && root.stats.gpuMemTotalGiB > 0 ? root.stats.gpuMemUsedGiB / root.stats.gpuMemTotalGiB * 100 : 0
    }

    PanelDivider {}

    PanelCaption { text: "Disks" }
    Repeater {
      model: root.stats ? root.stats.disks : []
      StatRow {
        required property var modelData
        label: modelData.mount
        value: root.pctTemp(modelData.percent, modelData.temp) + "  " + root.gibText(modelData.usedGiB, modelData.totalGiB)
        percent: modelData.percent
      }
    }
    Text {
      visible: !root.stats || root.stats.disks.length === 0
      text: "No mounts reported"
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontBody
    }

    PanelDivider { visible: root.stats && root.stats.btopAvailable }

    PanelButton {
      visible: root.stats && root.stats.btopAvailable
      icon: "󰄪"
      text: "Open btop"
      highlighted: true
      onClicked: root.openBtop()
    }
  }
}
