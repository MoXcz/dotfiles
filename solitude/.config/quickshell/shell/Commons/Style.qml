pragma Singleton
import QtQuick
import qs.Commons

// Compatibility shim for panels ported from omarchy (modules/displays).
// Omarchy's kit styles everything through `Style.*` tokens; this maps the
// subset those panels touch onto Theme so the ported files keep their
// styling calls while every color and size still comes from one place.
// Solitude's own modules use Theme directly; do not grow this beyond what
// the ported code needs.
QtObject {
  id: root

  readonly property int cornerRadius: Theme.cornerRadius
  readonly property int normalBorderWidth: Theme.borderWidth

  // Omarchy scales pixel sizes by a theme factor; this shell does not.
  function space(px) {
    var n = Number(px)
    if (!isFinite(n) || n <= 0) return 0
    return Math.max(1, Math.round(n))
  }

  readonly property QtObject spacing: QtObject {
    readonly property int hairline: 1
    readonly property int xxs: 2
    readonly property int xs: 3
    readonly property int sm: 4
    readonly property int md: 6
    readonly property int huge: 18
    readonly property int controlGap: 8
    readonly property int controlPaddingX: 10
    readonly property int controlPaddingY: 6
    readonly property int inputPaddingY: 7
    readonly property int controlHeight: 28
    readonly property int popupRowHeight: 28
    readonly property int dropdownWidth: 240
    readonly property int numberFieldWidth: 120
    readonly property int rowPaddingX: 12
    readonly property int labelGap: 4
  }

  readonly property QtObject font: QtObject {
    readonly property string family: Theme.fontFamily
    readonly property int caption: Theme.fontCaption
    readonly property int bodySmall: Math.round(Config.fontSize * 0.917)
    readonly property int body: Theme.fontBody
    readonly property int subtitle: Math.round(Config.fontSize * 1.083)
    readonly property int title: Theme.fontTitle
    readonly property int heading: Theme.fontHeading
    readonly property int display: Math.round(Config.fontSize * 2)
    readonly property int icon: Theme.fontTitle
  }

  // State fills. Omarchy derives these from a foreground/accent pair passed
  // by the caller; this shell has fixed tokens, so the arguments are ignored.
  function hoverStateColor(foreground, accent, urgent) { return Theme.foreground }
  function selectedStateColor(foreground, accent, urgent) { return Theme.accent }
  function normalFill() { return Theme.surfaceAlt }
  function hoverFillFor(foreground, accent, urgent) { return Theme.hover }
  function selectedFillFor(foreground, accent, urgent) { return Theme.selected }
  function pressedFillFor(foreground, accent, urgent) { return Util.alpha(Theme.foreground, 0.14) }
  function controlFill(focused, hot, foreground, accent) {
    if (focused || hot) return Theme.hover
    return Theme.surfaceAlt
  }
}
