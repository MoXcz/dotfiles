import QtQuick
import qs.Commons

// Rectangle that takes its border from a Border spec ({ color, widths }).
// Ported from omarchy's kit for modules/displays; our borders are
// uniform, so the native Rectangle border is always enough. The inset
// properties let content anchor inside the border plus padding.
Rectangle {
  id: root

  property var borderSpec: Border.none()
  property real padding: 0
  property real topPadding: padding
  property real rightPadding: padding
  property real bottomPadding: padding
  property real leftPadding: padding

  readonly property real borderTop: Border.top(borderSpec)
  readonly property real borderRight: Border.right(borderSpec)
  readonly property real borderBottom: Border.bottom(borderSpec)
  readonly property real borderLeft: Border.left(borderSpec)
  readonly property real contentTopInset: borderTop + topPadding
  readonly property real contentRightInset: borderRight + rightPadding
  readonly property real contentBottomInset: borderBottom + bottomPadding
  readonly property real contentLeftInset: borderLeft + leftPadding

  border.color: Border.color(borderSpec)
  border.width: Border.uniformWidth(borderSpec)
}
