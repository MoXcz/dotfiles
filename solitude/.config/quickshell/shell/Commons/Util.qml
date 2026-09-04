pragma Singleton
import QtQuick
import Quickshell

// Pure helpers shared by every module. No state here.
QtObject {
  id: root

  function clamp(value, min, max) {
    var n = Number(value)
    if (!isFinite(n)) return min
    return Math.max(min, Math.min(max, n))
  }

  // Compose a color (object or hex string) with an opacity.
  function alpha(c, opacity) {
    var a = clamp(opacity, 0, 1)
    if (!c) return Qt.rgba(0, 0, 0, a)
    if (typeof c === "string") c = Qt.color(c)
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  function fileUrl(path) {
    if (!path) return ""
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
  }

  function shellQuote(value) {
    return "'" + String(value || "").replace(/'/g, "'\\''") + "'"
  }

  // Run a shell command line detached from the shell process.
  function exec(command) {
    Quickshell.execDetached(["bash", "-lc", command])
  }

  // Run an argv vector without shell interpretation.
  function execArgv(argv) {
    Quickshell.execDetached(["bash", "-lc", 'exec "$@"', "bash"].concat(argv))
  }

  function truncate(text, max) {
    var s = String(text || "")
    if (s.length <= max) return s
    return s.slice(0, Math.max(0, max - 1)) + "…"
  }

  // Simple subsequence fuzzy match. Returns a score (lower is better) or -1.
  function fuzzyScore(query, text) {
    var q = String(query || "").toLowerCase()
    var t = String(text || "").toLowerCase()
    if (!q) return 0
    var idx = t.indexOf(q)
    if (idx === 0) return 0
    if (idx > 0) return 1 + idx
    var ti = 0, score = 100, last = -1
    for (var qi = 0; qi < q.length; qi++) {
      ti = t.indexOf(q.charAt(qi), ti)
      if (ti < 0) return -1
      score += (ti - last - 1)
      last = ti
      ti++
    }
    return score
  }

  // ISO 8601 week number (weeks start Monday, week 1 holds Jan 4th).
  function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    var day = d.getUTCDay() || 7
    d.setUTCDate(d.getUTCDate() + 4 - day)
    var yearStart = Date.UTC(d.getUTCFullYear(), 0, 1)
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
  }

  // Qt.formatDateTime plus a "{w}" token for the ISO week number.
  function formatTime(date, format) {
    return Qt.formatDateTime(date, format).replace("{w}", isoWeek(date))
  }

  // Standard filter-editing keys: Backspace, Ctrl+Backspace (word), Ctrl+U.
  function editsFilter(event, text) {
    if (!text) return false
    if (event.modifiers & (Qt.AltModifier | Qt.MetaModifier)) return false
    if (event.key === Qt.Key_U) return event.modifiers === Qt.ControlModifier
    return event.key === Qt.Key_Backspace
  }

  function editedFilter(event, text) {
    if (event.key === Qt.Key_U) return ""
    if (event.modifiers & Qt.ControlModifier) return text.replace(/\s+$/, "").replace(/\S+$/, "")
    return text.slice(0, -1)
  }
}
