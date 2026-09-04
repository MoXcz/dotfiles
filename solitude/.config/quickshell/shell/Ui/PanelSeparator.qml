import QtQuick
import qs.Commons

// Hairline between panel sections (omarchy kit port; modules/displays).
Rectangle {
  property color foreground: Theme.foreground
  width: parent ? parent.width : implicitWidth
  implicitWidth: 100
  implicitHeight: Theme.borderWidth
  height: Theme.borderWidth
  color: Theme.border
}
