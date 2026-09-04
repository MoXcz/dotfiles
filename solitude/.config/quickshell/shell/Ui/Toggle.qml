import QtQuick
import qs.Commons

// Labeled toggle row: title + optional description on the left, a switch on
// the right. The row is stateless: it emits `clicked()` and the owner flips
// `checked`, so the pill always tracks real state (omarchy kit port).
BorderSurface {
  id: root

  property string label: ""
  property string description: ""
  property bool checked: false
  property bool hasCursor: false
  property color foreground: Theme.foreground
  property color accent: Theme.accent
  property string fontFamily: Theme.fontFamily
  property real titleSize: Style.font.subtitle
  property real descriptionSize: Theme.fontCaption

  signal clicked()
  signal hovered(bool isHovered)

  activeFocusOnTab: true
  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()

  implicitHeight: Math.max(54, content.implicitHeight + Style.spacing.huge)
  implicitWidth: 240
  radius: Theme.cornerRadius
  opacity: enabled ? 1 : 0.45

  readonly property bool _hot: hasCursor || mouse.containsMouse

  color: Style.controlFill(activeFocus, _hot)
  borderSpec: Border.controlSpec(activeFocus ? "focus" : (_hot ? "hover-cursor" : "normal"))

  Behavior on color { ColorAnimation { duration: 100 } }

  Row {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: root.borderLeft + Style.spacing.rowPaddingX
    anchors.rightMargin: root.borderRight + Style.spacing.rowPaddingX
    spacing: Style.spacing.rowPaddingX

    Column {
      width: parent.width - track.width - parent.spacing
      spacing: Style.spacing.xs
      anchors.verticalCenter: parent.verticalCenter

      Text {
        textFormat: Text.PlainText
        text: root.label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: root.titleSize
        font.bold: true
        elide: Text.ElideRight
        width: parent.width
      }

      Text {
        textFormat: Text.PlainText
        visible: root.description !== ""
        text: root.description
        color: Theme.muted
        font.family: root.fontFamily
        font.pixelSize: root.descriptionSize
        wrapMode: Text.WordWrap
        width: parent.width
      }
    }

    // Presentation only; the row owns the click.
    Rectangle {
      id: track
      anchors.verticalCenter: parent.verticalCenter
      width: 34
      height: 18
      radius: height / 2
      color: root.checked ? Theme.accent : Theme.surfaceAlt
      border.color: root.checked ? Theme.accent : Theme.border
      border.width: Theme.borderWidth

      Rectangle {
        readonly property int inset: 3
        width: parent.height - inset * 2
        height: width
        radius: width / 2
        y: inset
        x: root.checked ? parent.width - width - inset : inset
        color: root.checked ? Theme.background : Theme.muted
        Behavior on x { NumberAnimation { duration: 90 } }
      }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  HoverHandler {
    onHoveredChanged: root.hovered(hovered)
  }
}
