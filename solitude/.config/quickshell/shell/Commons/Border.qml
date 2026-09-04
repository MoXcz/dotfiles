pragma Singleton
import QtQuick
import qs.Commons

// Compatibility shim for panels ported from omarchy (modules/displays).
// Omarchy describes borders as a spec object ({ color, widths }) so a
// surface can carry per-side widths and gradients. Solitude only draws
// uniform hairlines, so a spec here is just color + one width, expressed in
// the same shape so ported components read it unchanged.
QtObject {
  id: root

  function flat(color, width) {
    var w = Math.max(0, Math.round(Number(width) || 0))
    return { color: color || "transparent", widths: { top: w, right: w, bottom: w, left: w } }
  }

  function none() { return flat("transparent", 0) }

  // Control chrome by interaction state. The state names come from omarchy:
  // normal, hover-cursor (mouse hover or keyboard cursor), selected, focus.
  function controlSpec(state, foreground, accent, urgent) {
    var s = String(state || "normal")
    if (s === "focus") return flat(Theme.accent, Theme.borderWidth)
    if (s === "selected") return flat(Util.alpha(Theme.accent, 0.7), Theme.borderWidth)
    if (s === "hover-cursor" || s === "hover" || s === "hot") return flat(Util.alpha(Theme.foreground, 0.3), Theme.borderWidth)
    return flat(Theme.border, Theme.borderWidth)
  }

  // Themed surface borders (popups, tooltips). Solitude has no per-surface
  // theming, so the caller's fallback color is the answer.
  function surfaceSpec(section, token, fallbackColor, fallbackWidth, alphaKey) {
    return flat(fallbackColor, fallbackWidth)
  }

  function localOrSurfaceSpec(section, token, localColor, defaultColor, fallbackWidth, alphaKey) {
    return flat(localColor, fallbackWidth)
  }

  function top(spec) { return spec && spec.widths ? spec.widths.top : 0 }
  function right(spec) { return spec && spec.widths ? spec.widths.right : 0 }
  function bottom(spec) { return spec && spec.widths ? spec.widths.bottom : 0 }
  function left(spec) { return spec && spec.widths ? spec.widths.left : 0 }
  function uniformWidth(spec) { return top(spec) }
  function color(spec) { return spec ? spec.color : "transparent" }
}
