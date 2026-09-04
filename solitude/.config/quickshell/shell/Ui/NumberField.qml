import QtQuick
import QtQuick.Controls as QQC
import qs.Commons

// Labeled integer spin box (omarchy kit port; modules/displays). `field`
// exposes the SpinBox so the panel can hand it keyboard focus.
Column {
  id: root

  property string label: ""
  property int value: 0
  property int from: 0
  property int to: 100
  property int stepSize: 1
  property color foreground: Theme.foreground
  property color accent: Theme.accent
  property string fontFamily: Theme.fontFamily
  property real fontSize: Theme.fontBody
  property real fieldWidth: Style.spacing.numberFieldWidth
  property bool hasCursor: false
  property bool _hovered: false
  property alias field: spin

  signal modified(int value)
  signal hovered(bool on)

  spacing: Style.spacing.md
  opacity: enabled ? 1 : 0.45

  Text {
    textFormat: Text.PlainText
    visible: root.label !== ""
    text: root.label
    color: Theme.muted
    font.family: root.fontFamily
    font.pixelSize: Theme.fontCaption
    font.bold: true
  }

  QQC.SpinBox {
    id: spin
    width: root.fieldWidth
    implicitHeight: Math.max(Style.spacing.controlHeight, root.fontSize + Style.spacing.controlPaddingY * 2)
    from: root.from
    to: root.to
    stepSize: root.stepSize
    value: root.value
    editable: true
    font.family: root.fontFamily
    font.pixelSize: root.fontSize

    readonly property bool _focused: spin.activeFocus
    readonly property bool _hot: root._hovered || root.hasCursor
    readonly property var _borderSpec: Border.controlSpec(_focused ? "focus" : (_hot ? "hover-cursor" : "normal"))

    leftPadding: Border.left(_borderSpec) + Style.spacing.controlPaddingX
    rightPadding: Border.right(_borderSpec) + Style.spacing.controlPaddingX
    topPadding: Border.top(_borderSpec)
    bottomPadding: Border.bottom(_borderSpec)

    onValueModified: root.modified(value)

    // The default style draws its own +/- indicators; hide them so the field
    // reads as a plain themed input (arrow keys and wheel still step).
    up.indicator: Item {}
    down.indicator: Item {}

    background: BorderSurface {
      color: Style.controlFill(spin._focused, spin._hot)
      borderSpec: spin._borderSpec
      radius: Theme.cornerRadius

      HoverHandler {
        onHoveredChanged: {
          root._hovered = hovered
          root.hovered(hovered)
        }
      }
    }

    contentItem: TextInput {
      text: spin.displayText
      font: spin.font
      color: root.foreground
      selectionColor: Theme.selected
      selectedTextColor: root.foreground
      horizontalAlignment: Qt.AlignHCenter
      verticalAlignment: Qt.AlignVCenter
      readOnly: !spin.editable
      validator: spin.validator
      inputMethodHints: Qt.ImhFormattedNumbersOnly
    }
  }
}
