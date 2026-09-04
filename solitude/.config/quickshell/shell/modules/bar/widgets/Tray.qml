import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons

// StatusNotifier icons. Left click activates, middle click is the secondary
// action, right click (or left click on menu-only items) opens the menu.
Item {
  id: root

  // Read by WidgetSlot; binding visible directly would loop through the Loader.
  property bool shown: count > 0

  readonly property int iconSize: Theme.fontIcon + 4
  readonly property int count: SystemTray.items.values.filter(function(item) {
    return item.status !== Status.Passive
  }).length

  implicitWidth: row.implicitWidth + Theme.spaceSm * 2

  Row {
    id: row
    x: Theme.spaceSm
    height: root.height
    spacing: Theme.spaceSm

    Repeater {
      model: SystemTray.items

      Item {
        id: cell
        required property var modelData

        visible: modelData.status !== Status.Passive
        width: root.iconSize + Theme.space
        height: parent.height

        Rectangle {
          anchors.fill: parent
          anchors.topMargin: Theme.spaceSm
          anchors.bottomMargin: Theme.spaceSm
          radius: Theme.cornerRadius
          color: area.containsMouse ? Theme.hover : "transparent"
        }

        IconImage {
          anchors.centerIn: parent
          source: cell.modelData.icon
          implicitSize: root.iconSize
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: function(event) {
            var item = cell.modelData
            if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && item.onlyMenu)) {
              if (item.hasMenu) menu.openFor(item, cell)
            } else if (event.button === Qt.MiddleButton) {
              item.secondaryActivate()
            } else {
              item.activate()
            }
          }
          onWheel: function(event) { cell.modelData.scroll(event.angleDelta.y, false) }
        }
      }
    }
  }

  TrayMenu { id: menu }
}
