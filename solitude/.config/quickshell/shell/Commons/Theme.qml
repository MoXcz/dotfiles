pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Colors and structural tokens. The palette comes from the active theme
// (~/.config/shell/themes/<name>/colors.json, selected with
// theme); the values below are the fallback when no theme is set or
// its file cannot be read. Corner radius and outer gap are picked up from
// Hyprland so the shell matches the window decorations.
QtObject {
  id: root

  // ---------------------------------------------------------------- palette
  // Parsed colors.json of the active theme, empty until one loads.
  property var palette: ({})
  property string themeName: "solitude"

  // A token reads from the theme and falls back to the built-in value, so a
  // theme file may define as few colors as it likes.
  function themed(key, fallback) {
    var value = palette[key]
    return (typeof value === "string" && value.length > 0) ? value : fallback
  }

  readonly property color background: themed("background", "#101315")
  readonly property color surface: themed("surface", "#171b1e")
  readonly property color surfaceAlt: themed("surfaceAlt", "#1f2428")
  readonly property color border: themed("border", "#2c3338")
  readonly property color foreground: themed("foreground", "#cacccc")
  readonly property color muted: themed("muted", "#707880")
  readonly property color accent: themed("accent", "#8fb4d8")
  readonly property color urgent: themed("urgent", "#d27878")
  readonly property color success: themed("success", "#9ac27c")
  readonly property color warning: themed("warning", "#e0b46a")

  readonly property color scrim: Util.alpha("#000000", 0.35)
  readonly property color selected: Util.alpha(accent, 0.22)
  readonly property color hover: Util.alpha(foreground, 0.08)

  // ---------------------------------------------------------------- typography
  // Nerd Fonts carry icon glyphs but no emoji. Rather than list families per
  // Text, the emoji font is installed and fontconfig falls back to it for the
  // codepoints the Nerd Font has no glyph for.
  readonly property string fontFamily: Config.fontFamily
  readonly property int fontCaption: Math.round(Config.fontSize * 0.85)
  readonly property int fontBody: Config.fontSize
  readonly property int fontTitle: Math.round(Config.fontSize * 1.2)
  readonly property int fontHeading: Math.round(Config.fontSize * 1.4)
  readonly property int fontDisplay: Math.round(Config.fontSize * 4)
  readonly property int fontIcon: Math.round(Config.fontSize * 1.15)

  // ---------------------------------------------------------------- spacing
  readonly property int space: 8
  readonly property int spaceSm: 4
  readonly property int spaceLg: 14
  readonly property int spaceXl: 20
  readonly property int borderWidth: 1

  // Mirrors Hyprland decoration:rounding and half of general:gaps_out.
  property int cornerRadius: 6
  // Bar popups are bubbles, rounder than windows.
  readonly property int bubbleRadius: 16
  property int gapsOut: 5

  function applyRounding(raw) {
    try {
      var n = Number(JSON.parse(raw || "{}").int)
      if (isFinite(n) && n >= 0) cornerRadius = n
    } catch (e) { }
  }

  function applyGaps(raw) {
    try {
      var json = JSON.parse(raw || "{}")
      var parts = String(json.css || "").match(/-?\d+(?:\.\d+)?/g) || []
      var n = parts.length > 0 ? Number(parts[0]) : Number(json.int)
      if (isFinite(n) && n >= 0) gapsOut = Math.max(0, Math.round(n / 2))
    } catch (e) { }
  }

  // The state file holds the theme name; watching it means `theme
  // set` repaints the shell without a reload.
  property FileView nameFile: FileView {
    path: Config.stateDir + "/theme"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.themeName = String(text()).trim() || "solitude"
    onLoadFailed: root.themeName = "solitude"
  }

  property FileView colorsFile: FileView {
    path: Config.home + "/.config/shell/themes/" + root.themeName + "/colors.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.palette = JSON.parse(text()) || {} } catch (e) { root.palette = {} }
    }
    onLoadFailed: root.palette = {}
  }

  property Process roundingProc: Process {
    command: ["hyprctl", "-j", "getoption", "decoration:rounding"]
    stdout: StdioCollector { onStreamFinished: root.applyRounding(text) }
  }

  property Process gapsProc: Process {
    command: ["hyprctl", "-j", "getoption", "general:gaps_out"]
    stdout: StdioCollector { onStreamFinished: root.applyGaps(text) }
  }

  function refresh() {
    roundingProc.running = true
    gapsProc.running = true
    nameFile.reload()
    colorsFile.reload()
  }

  Component.onCompleted: refresh()
}
