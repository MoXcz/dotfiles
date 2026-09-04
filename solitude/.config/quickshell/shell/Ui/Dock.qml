import QtQuick
import qs.Commons

// Floating pill that groups bar widgets, phone-dock style. Hugs its
// content; the bar places one per section. `align` says which way it is
// pinned so a panel morphing out of it knows where to grow from, and
// `flat` drops the pill's own paint while such a panel is up, leaving the
// icons drawn over the panel card.
Rectangle {
  id: root

  default property alias content: row.data
  property int paddingX: Theme.space
  property int spacing: Theme.spaceSm
  property string align: "center"     // left | center | right
  property bool flat: false
  readonly property bool isDock: true
  readonly property bool hovered: hover.hovered

  // A single icon gets a circle rather than a squashed pill.
  implicitWidth: Math.max(implicitHeight, row.implicitWidth + paddingX * 2)
  implicitHeight: Config.bar.dockHeight
  radius: height / 2
  color: flat ? "transparent" : Theme.surface
  border.width: Theme.borderWidth
  border.color: flat ? "transparent" : Theme.border
  Behavior on color { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }

  HoverHandler { id: hover }

  Row {
    id: row
    anchors.centerIn: parent
    height: root.height
    spacing: root.spacing
  }
}
