import QtQuick
import qs.Commons
import qs.Ui
import "../../menu/Routes.js" as Routes

// Calendar and picker content use the same morphing host as every other bar
// panel. Changing mode therefore resizes one surface instead of replacing it
// with a separate center window.
BarPopup {
  id: root

  property string mode: ""
  readonly property var modes: ["calendar", "theme", "background"]
  readonly property int targetWidth: mode === "calendar" ? Config.center.calendarWidth : Config.center.carouselWidth

  panelWidth: targetWidth

  function open(which, cell) {
    if (modes.indexOf(which) < 0) return
    mode = which
    openFor(cell)
  }

  function switchTo(which) {
    if (which === mode || modes.indexOf(which) < 0) return
    mode = which
    if (content.item && content.item.load) {
      content.item.route = Routes.picker(mode)
      content.item.load()
    }
  }

  function close() { dismiss() }

  function handleKey(event) {
    if (content.item && content.item.handleKey && content.item.handleKey(event)) return true
    return false
  }

  onVisibleChanged: if (!visible) mode = ""

  Loader {
    id: content
    width: parent.width
    height: item ? item.implicitHeight : 0
    sourceComponent: root.mode === "calendar" ? calendarComp
                   : root.mode === "theme" || root.mode === "background" ? carouselComp : null
    onLoaded: {
      if (root.mode === "calendar") item.reset()
      else {
        item.route = Routes.picker(root.mode)
        item.load()
      }
    }
  }

  Component { id: calendarComp; CalendarView {} }
  Component {
    id: carouselComp
    Carousel { onActivated: root.close() }
  }
}
