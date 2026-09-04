import QtQuick
import QtQuick.Controls
import qs.Commons

// Single-line input with the panel's focus/hover chrome. Subclasses the Qt
// Quick Controls TextField so text, placeholderText, validator, accepted,
// editingFinished and friends are all available (omarchy kit port;
// modules/displays).
TextField {
  id: root

  property color foreground: Theme.foreground
  property color accent: Theme.accent
  property color selectionTint: Theme.selected
  property bool password: false
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.inputPaddingY
  // Keyboard-cursor flag driven by the owning panel.
  property bool hasCursor: false

  readonly property bool _focused: activeFocus
  readonly property bool _hot: hovered || hasCursor
  readonly property var _borderSpec: Border.controlSpec(_focused ? "focus" : (_hot ? "hover-cursor" : "normal"))

  echoMode: password ? TextInput.Password : TextInput.Normal
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontBody
  color: foreground
  selectionColor: selectionTint
  selectedTextColor: foreground
  placeholderTextColor: Theme.muted
  opacity: enabled ? 1 : 0.45

  leftPadding: horizontalPadding + Border.left(_borderSpec)
  rightPadding: horizontalPadding + Border.right(_borderSpec)
  topPadding: verticalPadding + Border.top(_borderSpec)
  bottomPadding: verticalPadding + Border.bottom(_borderSpec)

  background: BorderSurface {
    color: Style.controlFill(root._focused, root._hot)
    borderSpec: root._borderSpec
    radius: Theme.cornerRadius
  }
}
