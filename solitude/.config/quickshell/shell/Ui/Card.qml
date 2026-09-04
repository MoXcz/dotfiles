import QtQuick
import qs.Commons

// Rounded, bordered surface used by every popup.
Rectangle {
  color: Theme.surface
  border.color: Theme.border
  border.width: Theme.borderWidth
  radius: Theme.cornerRadius
  clip: true
}
