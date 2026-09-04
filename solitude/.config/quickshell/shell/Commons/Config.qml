pragma Singleton
import QtQuick
import Quickshell

// User configuration for the shell. Edit this file; the shell
// reloads on save. Everything the modules can be tuned with lives here so
// there is a single place to look.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/shell"

  // ---------------------------------------------------------------- general
  readonly property string terminal: "kitty"
  readonly property string fontFamily: "Iosevka Nerd Font"
  // Used only where emoji can appear; a Nerd Font has none of its own.
  readonly property string emojiFontFamily: "Noto Color Emoji"
  readonly property int fontSize: 12

  // ---------------------------------------------------------------- bar
  readonly property var bar: ({
    position: "top",             // "top" | "bottom"
    height: 44,                  // reserved strip; the docks float inside it
    dockHeight: 34,              // pill height
    marginX: 10,                 // horizontal gap from the screen edge
    marginY: 5,                  // gap between the docks and the screen edge
    // Widget ids: workspaces, activeWindow, clock, tray, system, displays, bluetooth, network, wifi, vpn, windows, audio, battery, spacer
    // Left and right share one dock each; every center widget floats in its
    // own bubble. `wifi` is the network widget without the name. The right
    // dock shows `right` and unfolds `rightMore` to its left on hover.
    left: ["workspaces", "activeWindow"],
    center: ["clock", "wifi"],
    right: ["system", "audio", "battery"],
    rightMore: ["tray", "displays", "bluetooth", "vpn", "windows"],
    clockFormat: "W{w}  ddd d MMM  HH:mm",
    clockFormatAlt: "yyyy-MM-dd W{w}  HH:mm:ss",
    workspaceCount: 5,           // always show at least this many workspace slots
    workspaceSize: 24,           // circle diameter
    workspaceFocusedWidth: 42,   // the focused one stretches into a pill this wide
    // Per-workspace icon instead of the number: a desktop icon name (or a
    // list of candidates, first installed wins), an absolute path, or a
    // single glyph. Workspaces not listed show their number.
    workspaceIcons: ({
      1: "nvim",
      2: ["zen-browser", "firefox"],
      3: "obsidian"
    }),
    activeWindowMaxWidth: 220    // px before the focused window title is cut
  })

  // ---------------------------------------------------------------- launcher
  readonly property var launcher: ({
    width: 620,
    maxRows: 9,
    rowHeight: 44,
    placeholder: "Search applications…",
    // Prefixes that switch the launcher into a mode.
    runPrefix: ">",              // "> cmd" runs cmd in a shell
    terminalPrefix: "!",         // "! cmd" runs cmd inside the terminal
    calcPrefix: "="              // "= 2+2" evaluates an expression
  })

  // ---------------------------------------------------------------- menu
  readonly property var menu: ({
    width: 520,
    maxRows: 9,
    rowHeight: 44,
    animationMs: 140,            // route slide duration
    slidePx: 24                  // how far a route slides in from the side
  })

  // ---------------------------------------------------------------- center panel
  // Calendar, theme and background switcher morphing out of the clock pill.
  readonly property var center: ({
    calendarWidth: 300,
    carouselWidth: 640,
    tileWidth: 180,
    tileHeight: 110,
    animationMs: 320
  })

  // ---------------------------------------------------------------- dock panels
  // Widget panels (audio, battery, system, …) morph out of their dock.
  readonly property var dockPanel: ({
    animationMs: 300,
    collapseDelayMs: 350,        // how long the right dock stays unfolded after the pointer leaves
    linger: 2000                 // and after one of its panels closes
  })

  // ---------------------------------------------------------------- keybindings
  readonly property var keybindings: ({
    width: 680,
    maxRows: 12,
    rowHeight: 40,
    placeholder: "Search keybindings…"
  })

  // ---------------------------------------------------------------- clipboard
  readonly property var clipboard: ({
    width: 760,
    height: 520,
    rowHeight: 52,
    historyLimit: 300,
    maxTextBytes: 1048576,       // entries larger than this are not stored
    pasteOnSelect: true,         // send Ctrl+V to the focused window after copy
    placeholder: "Search clipboard…"
  })

  // ---------------------------------------------------------------- notifications
  readonly property var notifications: ({
    width: 400,
    timeoutMs: 6000,             // 0 = never auto-dismiss
    criticalTimeoutMs: 0,
    maxVisible: 5,
    corner: "top-right",         // "top-right" | "top-left" | "bottom-right" | "bottom-left"
    margin: 12,
    historyLimit: 100
  })

  // ---------------------------------------------------------------- vpn
  // Backed by strongSwan's swanctl through `vpn`; run
  // `vpn setup` once so the widget can drive it without a password.
  readonly property var vpn: ({
    connection: "",              // swanctl connection name, "" = first configured
    pollMs: 5000,                // how often the bar re-reads the tunnel state
    showLabel: true,             // connection name next to the glyph while up
    alwaysShow: false            // keep the widget when swanctl is missing
  })

  // ---------------------------------------------------------------- windows
  // Windows VM (dockur/windows) driven through `windows-vm`; the
  // widget appears once `windows-vm install` has run.
  readonly property var windows: ({
    pollMs: 5000,                // how often the bar re-reads the VM state
    showLabel: true,             // "…" next to the glyph while the guest boots
    alwaysShow: false            // keep the widget when the VM is not installed
  })

  // ---------------------------------------------------------------- osd
  readonly property var osd: ({
    timeoutMs: 1500,
    width: 300,
    position: "bottom-center",   // "bottom-center" | "top-center" | "center"
    margin: 64                   // distance from the screen edge for top/bottom positions
  })

  // ---------------------------------------------------------------- displays
  // Backed by hyprmoncfg (https://github.com/crmne/hyprmoncfg).
  readonly property var displays: ({
    canvasWidth: 520,
    snapPx: 24
  })

  // ---------------------------------------------------------------- lock
  readonly property var lock: ({
    pamConfig: "login",
    background: "",              // absolute path to an image, empty = solid color
    clockFormat: "HH:mm",
    dateFormat: "dddd, d MMMM",
    blurBackground: true
  })
}
