import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Popup listing a tray item's DBus menu. Platform menus (QsMenuAnchor) need
// QApplication mode, which the shell does not run in, so the entries are
// drawn here from a QsMenuOpener instead.
PopupWindow {
  id: root

  property var trayItem: null
  property var anchorItem: null
  // Submenu drill-down. Each level keeps its own opener because a parent
  // opener owns the entry objects its children point at.
  property var stack: []
  readonly property var entries: stack.length > 0 ? stack[stack.length - 1].children.values : rootOpener.children.values
  readonly property bool atBottom: Config.bar.position === "bottom"
  readonly property int rowHeight: Theme.fontBody + Theme.space * 2

  function openFor(item, cell) {
    if (visible && trayItem === item) {
      dismiss()
      return
    }
    reset()
    trayItem = item
    anchorItem = cell
    visible = true
  }

  function dismiss() {
    visible = false
  }

  function reset() {
    var old = stack
    stack = []
    for (var i = old.length - 1; i >= 0; i--) old[i].destroy()
  }

  function enter(entry) {
    var opener = openerComp.createObject(root, { menu: entry })
    if (!opener) return
    var next = stack.slice()
    next.push(opener)
    stack = next
  }

  function back() {
    var next = stack.slice()
    var top = next.pop()
    stack = next
    if (top) top.destroy()
  }

  function trigger(entry) {
    if (entry.hasChildren) {
      enter(entry)
      return
    }
    entry.triggered()
    dismiss()
  }

  visible: false
  grabFocus: true
  color: "transparent"
  implicitWidth: card.implicitWidth
  implicitHeight: card.implicitHeight
  anchor.item: anchorItem
  anchor.edges: (atBottom ? Edges.Top : Edges.Bottom) | Edges.Left
  anchor.gravity: (atBottom ? Edges.Top : Edges.Bottom) | Edges.Right
  anchor.margins.top: Theme.spaceSm
  anchor.margins.bottom: Theme.spaceSm

  // grabFocus hides the popup on an outside click; drop the menu state then too.
  onVisibleChanged: if (!visible) { reset(); trayItem = null }

  Component { id: openerComp; QsMenuOpener {} }
  QsMenuOpener { id: rootOpener; menu: root.trayItem ? root.trayItem.menu : null }

  Card {
    id: card
    anchors.fill: parent
    implicitWidth: Math.max(180, column.implicitWidth + Theme.space * 2)
    implicitHeight: column.implicitHeight + Theme.space * 2

    Column {
      id: column
      anchors.fill: parent
      anchors.margins: Theme.space

      Rectangle {
        visible: root.stack.length > 0
        width: parent.width
        height: root.rowHeight
        radius: Theme.cornerRadius
        color: backArea.containsMouse ? Theme.hover : "transparent"
        Text {
          anchors.verticalCenter: parent.verticalCenter
          x: Theme.space
          text: "󰅁  Back"
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontBody
        }
        MouseArea { id: backArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.back() }
      }

      Repeater {
        model: root.entries

        Item {
          id: entryRow
          required property var modelData
          readonly property bool checkable: modelData.buttonType !== QsMenuButtonType.None
          readonly property bool checked: modelData.checkState === Qt.Checked

          width: parent.width
          height: modelData.isSeparator ? Theme.spaceSm * 2 + Theme.borderWidth : root.rowHeight

          Rectangle {
            visible: entryRow.modelData.isSeparator
            anchors.centerIn: parent
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
          }

          Rectangle {
            visible: !entryRow.modelData.isSeparator
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: entryArea.containsMouse ? Theme.hover : "transparent"

            Row {
              anchors.verticalCenter: parent.verticalCenter
              x: Theme.space
              spacing: Theme.spaceSm

              Text {
                visible: entryRow.checkable
                anchors.verticalCenter: parent.verticalCenter
                text: entryRow.modelData.buttonType === QsMenuButtonType.RadioButton
                  ? (entryRow.checked ? "󰐾" : "󰄰")
                  : (entryRow.checked ? "󰄲" : "󰄱")
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontIcon
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String(entryRow.modelData.text).replace("&", "")
                color: entryRow.modelData.enabled ? Theme.foreground : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
              }

              Text {
                visible: entryRow.modelData.hasChildren
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontIcon
              }
            }

            MouseArea {
              id: entryArea
              anchors.fill: parent
              hoverEnabled: true
              enabled: entryRow.modelData.enabled
              onClicked: root.trigger(entryRow.modelData)
            }
          }
        }
      }
    }
  }
}
