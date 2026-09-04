import QtQuick
import qs.Commons

// Clickable chip/button used by the ported displays panel (omarchy kit
// port). States compose in priority order: pressed, focus ring, hover or
// keyboard cursor, selected, active, idle. Borderless at rest unless
// `bordered`; hover/focus always draw the cursor border so the keyboard
// target is visible.
BorderSurface {
  id: root

  property string text: ""
  property string iconText: ""
  property string tooltipText: ""   // accepted for API parity; not rendered

  property bool selected: false
  property bool active: false
  property bool hasCursor: false
  property bool focusable: false
  property bool bordered: false

  property color foreground: Theme.foreground
  property color background: "transparent"
  property color accent: Theme.accent

  property string fontFamily: Theme.fontFamily
  property real fontSize: Theme.fontBody
  property real iconSize: Theme.fontTitle
  property real iconRotation: 0
  property bool iconSpinning: false
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.controlPaddingY
  property bool leftAlign: false

  signal clicked()
  signal rightClicked()
  signal hovered(bool isHovered)

  activeFocusOnTab: focusable
  Keys.onReturnPressed: if (focusable) root.clicked()
  Keys.onEnterPressed: if (focusable) root.clicked()
  Keys.onSpacePressed: if (focusable) root.clicked()

  // Every state paints the same 1px border width, so size never jumps.
  implicitWidth: row.implicitWidth + horizontalPadding * 2 + Theme.borderWidth * 2
  implicitHeight: row.implicitHeight + verticalPadding * 2 + Theme.borderWidth * 2
  radius: Theme.cornerRadius
  opacity: enabled ? 1 : 0.45

  readonly property bool hot: mouseArea.containsMouse || hasCursor
  readonly property bool _showFocusRing: focusable && activeFocus
  readonly property color _selectedColor: Theme.accent

  color: mouseArea.pressed ? Style.pressedFillFor()
    : _showFocusRing ? Theme.hover
    : hot ? Theme.hover
    : (selected || active) ? Theme.selected
    : background

  borderSpec: _showFocusRing ? Border.controlSpec("focus")
    : hot ? Border.controlSpec("hover-cursor")
    : selected ? Border.controlSpec("selected")
    : bordered ? Border.controlSpec("normal")
    : Border.none()

  Behavior on color { ColorAnimation { duration: 120 } }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: root.leftAlign ? parent.left : undefined
    anchors.leftMargin: root.leftAlign ? Theme.borderWidth + root.horizontalPadding : 0
    anchors.horizontalCenter: root.leftAlign ? undefined : parent.horizontalCenter
    spacing: Style.spacing.controlGap

    Text {
      textFormat: Text.PlainText
      visible: root.iconText !== ""
      text: root.iconText
      color: root.selected ? root._selectedColor : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.iconSize
      rotation: root.iconSpinning ? 0 : root.iconRotation
      transformOrigin: Item.Center
      anchors.verticalCenter: parent.verticalCenter

      RotationAnimation on rotation {
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
        running: root.iconSpinning
      }
    }

    Text {
      textFormat: Text.PlainText
      visible: root.text !== ""
      text: root.text
      color: root.selected ? root._selectedColor : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      font.bold: root.selected
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (root.focusable) root.forceActiveFocus()
      if (mouse.button === Qt.RightButton) root.rightClicked()
      else root.clicked()
    }
  }

  HoverHandler {
    onHoveredChanged: root.hovered(hovered)
  }
}
