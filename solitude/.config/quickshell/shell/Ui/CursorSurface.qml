import QtQuick
import qs.Commons

// Row chrome for keyboard-and-mouse navigable items. Visuals derive from
// `hasCursor` / `current` only, never from containsMouse, so exactly one
// highlight exists on screen whether the cursor came from the mouse or the
// keyboard (omarchy kit port; modules/displays).
BorderSurface {
  id: root

  property bool hasCursor: false
  property bool current: false
  property bool outline: false
  property bool bordered: false
  property color foreground: Theme.foreground
  property color accent: Theme.accent
  property color fill: Theme.hover
  property color currentFill: Theme.selected

  radius: Theme.cornerRadius
  color: hasCursor ? fill : (current ? currentFill : "transparent")
  borderSpec: hasCursor ? Border.controlSpec("hover-cursor")
    : (current ? Border.controlSpec("selected")
      : (bordered ? Border.controlSpec("normal") : Border.none()))

  Behavior on color { ColorAnimation { duration: 60 } }
}
