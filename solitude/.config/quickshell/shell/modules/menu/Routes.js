.pragma library

// Menu contents. The root is one flat, searchable list of everything the
// shell can do; the only nested routes are pickers whose rows come from a
// command (keyboard, emoji). Theme and background use the same generator
// format but live in the clock's center panel as carousels (see `pickers`).
// A row is:
//   { glyph, title, subtitle, route }    push a picker route
//   { glyph, title, subtitle, command }  run a shell command line
//   { glyph, title, subtitle, argv }     run an argv vector, no shell
//   { glyph, title, subtitle, copy }     copy a string to the clipboard
//
// Subtitles start with a group name ("Capture · …") so typing the group
// filters to it. A row may add `requires: "<command>"`; the menu probes those
// commands once and hides rows whose command is not installed.
//
// A route may instead name a `generator`: an argv vector printing one row per
// line as "glyph<TAB>title<TAB>payload<TAB>subtitle<TAB>image". `run` is then
// the argv template for a chosen row, with the string "$PAYLOAD" replaced by
// that row's payload — the payload is never pasted into a shell line, so a
// title with quotes or spaces in it stays data. The image column is optional;
// the center panel's carousels show it as a preview.

var routes = {
  root: {
    title: "Search actions…",
    rows: [
      // Capture
      { glyph: "󰨏", title: "Screenshot region", subtitle: "Capture · Saves, copies, click the toast to edit", command: "screenshot" },
      { glyph: "󰹑", title: "Screenshot screen", subtitle: "Capture · Whole focused output", command: "screenshot fullscreen" },
      { glyph: "󰕧", title: "Screen recording", subtitle: "Capture · Start, or stop one already running", command: "screenrecord", requires: "wf-recorder" },
      { glyph: "󰴑", title: "Extract text (OCR)", subtitle: "Capture · Copy text out of a region", command: "ocr", requires: "tesseract" },
      { glyph: "󰉦", title: "Color picker", subtitle: "Capture · Copy a pixel's hex value", command: "pkill hyprpicker || hyprpicker -a", requires: "hyprpicker" },

      // Style
      { glyph: "󰉦", title: "Theme", subtitle: "Style · Switch the shell and border palette", argv: ["shell", "center", "open", "theme"] },
      { glyph: "󰋩", title: "Background", subtitle: "Style · Pick a wallpaper from any theme", argv: ["shell", "center", "open", "background"] },
      { glyph: "󰌌", title: "Keyboard layout", subtitle: "Style · Switch the active layout", route: "keyboard" },

      // Toggles
      { glyph: "󰕮", title: "Top bar", subtitle: "Toggle · Show or hide the bar", argv: ["shell", "bar", "toggle"] },
      { glyph: "󰂛", title: "Do not disturb", subtitle: "Toggle · Silence notification toasts", argv: ["shell", "notifications", "toggleDnd"] },
      { glyph: "󰦝", title: "VPN", subtitle: "Toggle · Connect or disconnect the IPsec tunnel", argv: ["vpn", "toggle"], requires: "swanctl" },
      { glyph: "󰒲", title: "Idle locking", subtitle: "Toggle · Stop or start hypridle", command: "toggle idle" },
      { glyph: "󰛨", title: "Nightlight", subtitle: "Toggle · Warm the display with hyprsunset", command: "toggle nightlight" },

      // Tools
      { glyph: "󰞅", title: "Emoji", subtitle: "Tools · Search and copy an emoji", route: "emoji" },
      { glyph: "󰈫", title: "Transcode", subtitle: "Tools · Re-encode a picture or video", command: "transcode", requires: "ffmpeg" },
      { glyph: "󰅍", title: "Share clipboard", subtitle: "Share · Send what is on the clipboard with LocalSend", command: "share clipboard", requires: "localsend" },
      { glyph: "󰈔", title: "Share files", subtitle: "Share · Pick files to send with LocalSend", command: "share file", requires: "localsend" },
      { glyph: "󰉋", title: "Share folder", subtitle: "Share · Pick a folder to send with LocalSend", command: "share folder", requires: "localsend" },

      // System
      { glyph: "󰌾", title: "Lock", subtitle: "System · Lock the session", argv: ["shell", "lock", "lock"] },
      { glyph: "󰤄", title: "Suspend", subtitle: "System · Sleep", argv: ["systemctl", "suspend"] },
      { glyph: "󰗽", title: "Log out", subtitle: "System · Ends the Hyprland session", argv: ["hyprctl", "dispatch", "exit"] },
      { glyph: "󰜉", title: "Restart", subtitle: "System · Reboot the machine", argv: ["systemctl", "reboot"] },
      { glyph: "󰐥", title: "Power off", subtitle: "System · Shut down", argv: ["systemctl", "poweroff"] }
    ]
  },

  keyboard: {
    title: "Keyboard",
    loading: "Reading layouts…",
    generator: ["keyboard", "list"],
    run: ["keyboard", "set", "$PAYLOAD"]
  },

  emoji: {
    title: "Emoji",
    loading: "Building emoji list…",
    generator: ["emoji"],
    copyPayload: true
  }
}

// Generator routes shown as carousels in the center panel, not in the menu.
var pickers = {
  theme: {
    loading: "Reading themes…",
    generator: ["theme", "list"],
    run: ["theme", "set", "$PAYLOAD"]
  },
  background: {
    loading: "Reading backgrounds…",
    generator: ["background", "list"],
    run: ["background", "set", "$PAYLOAD"]
  }
}

function picker(id) {
  return pickers[String(id || "")] || null
}

// Every command any row depends on, deduplicated, for a single probe.
function requirements() {
  var seen = {}
  for (var id in routes) {
    var rows = routes[id].rows || []
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].requires) seen[rows[i].requires] = true
    }
  }
  return Object.keys(seen)
}

function node(id) {
  return routes[String(id || "")] || null
}

// Turn a generator's output into rows. Unparseable lines are skipped rather
// than rendered as blanks.
function parseRows(text, route) {
  var out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i]) continue
    var parts = lines[i].split("\t")
    if (parts.length < 2) continue
    var payload = parts.length > 2 ? parts[2] : parts[1]
    var row = {
      glyph: parts[0],
      title: parts[1],
      subtitle: parts.length > 3 ? parts[3] : "",
      image: parts.length > 4 ? parts[4] : ""
    }
    if (route.copyPayload) {
      row.copy = payload
    } else if (route.run) {
      row.argv = route.run.map(function(arg) { return arg === "$PAYLOAD" ? payload : arg })
    }
    out.push(row)
  }
  return out
}
