import QtQuick
import qs.Commons

// Month view for the center panel: week numbers down the side, today ringed
// in the accent, arrows (or the wheel) to move months. Resets to the month
// that holds today each time it is shown.
Item {
  id: root

  readonly property int cellSize: 30
  implicitWidth: cellSize * 8 + Theme.spaceSm * 7
  implicitHeight: column.implicitHeight

  function reset() { today = new Date(); year = today.getFullYear(); month = today.getMonth() }
  // Arrow keys from the panel.
  function handleKey(event) {
    if (event.key === Qt.Key_Left) { shift(-1); return true }
    if (event.key === Qt.Key_Right) { shift(1); return true }
    return false
  }
  property date today: new Date()
  property int year: today.getFullYear()
  property int month: today.getMonth()      // 0-based

  readonly property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
  readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
                                     "July", "August", "September", "October", "November", "December"]

  onVisibleChanged: if (visible) reset()

  function shift(delta) {
    var m = month + delta
    year += Math.floor(m / 12)
    month = ((m % 12) + 12) % 12
  }

  // Six rows of seven days, Monday first, padded with the neighbouring
  // months so the grid never changes height.
  readonly property var cells: {
    var first = new Date(year, month, 1)
    var lead = (first.getDay() + 6) % 7
    var start = new Date(year, month, 1 - lead)
    var out = []
    for (var i = 0; i < 42; i++) {
      var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
      out.push({
        day: d.getDate(),
        inMonth: d.getMonth() === month,
        isToday: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate(),
        week: i % 7 === 0 ? Util.isoWeek(d) : 0
      })
    }
    return out
  }

  Column {
    id: column
    width: parent.width
    spacing: Theme.spaceSm

    // Month header with arrows on either side.
    Item {
      width: parent.width
      height: root.cellSize

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "󰅁"
        color: prevArea.containsMouse ? Theme.foreground : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontHeading
        MouseArea { id: prevArea; anchors.fill: parent; anchors.margins: -Theme.space; hoverEnabled: true; onClicked: root.shift(-1) }
      }

      Text {
        anchors.centerIn: parent
        text: root.monthNames[root.month] + " " + root.year
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontTitle
        font.weight: Font.DemiBold
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "󰅂"
        color: nextArea.containsMouse ? Theme.foreground : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontHeading
        MouseArea { id: nextArea; anchors.fill: parent; anchors.margins: -Theme.space; hoverEnabled: true; onClicked: root.shift(1) }
      }

      MouseArea {
        anchors.fill: parent
        z: -1
        onWheel: function(event) { root.shift(event.angleDelta.y < 0 ? 1 : -1) }
      }
    }

    // Day-of-week row, offset by the week-number column.
    Grid {
      columns: 8
      spacing: Theme.spaceSm
      Repeater {
        model: [""].concat(root.dayNames)
        Item {
          required property string modelData
          width: root.cellSize
          height: Math.round(root.cellSize * 0.7)
          Text {
            anchors.centerIn: parent
            text: modelData
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
          }
        }
      }
    }

    Grid {
      id: grid
      columns: 8
      spacing: Theme.spaceSm

      Repeater {
        // Insert a week-number cell before each row.
        model: {
          var out = []
          for (var i = 0; i < root.cells.length; i++) {
            if (i % 7 === 0) out.push({ week: root.cells[i].week })
            out.push(root.cells[i])
          }
          return out
        }

        Item {
          id: cell
          required property var modelData
          readonly property bool isWeek: modelData.day === undefined
          width: root.cellSize
          height: root.cellSize

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: cell.modelData.isToday ? Theme.selected : (dayArea.containsMouse && !cell.isWeek ? Theme.hover : "transparent")
            border.width: cell.modelData.isToday ? Theme.borderWidth : 0
            border.color: Theme.accent
          }

          Text {
            anchors.centerIn: parent
            text: cell.isWeek ? "W" + cell.modelData.week : String(cell.modelData.day)
            color: cell.isWeek ? Theme.muted
                 : cell.modelData.isToday ? Theme.accent
                 : cell.modelData.inMonth ? Theme.foreground : Util.alpha(Theme.muted, 0.6)
            font.family: Theme.fontFamily
            font.pixelSize: cell.isWeek ? Theme.fontCaption : Theme.fontBody
            font.weight: cell.modelData.isToday ? Font.Bold : Font.Normal
          }

          MouseArea {
            id: dayArea
            anchors.fill: parent
            hoverEnabled: !cell.isWeek
            onWheel: function(event) { root.shift(event.angleDelta.y < 0 ? 1 : -1) }
          }
        }
      }
    }
  }
}
