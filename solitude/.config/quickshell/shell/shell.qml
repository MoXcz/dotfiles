import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "modules/bar"
import "modules/launcher"
import "modules/menu"
import "modules/clipboard"
import "modules/keybindings"
import "modules/notifications"
import "modules/osd"

// The shell: one long-running Quickshell instance hosting the bar,
// launcher, command menu, clipboard manager, keybinding search,
// notification daemon, and OSD. The lock screen
// lives in a separate instance started from `lock.qml` in this directory.
//
// Control it from the outside with `shell <target> <function> [args]`
// (a thin wrapper over `qs -c shell ipc call`). Targets:
//   shell         toggle|open|close <launcher|clipboard|menu|keybindings>, ping, reload
//   menu          toggle|open [route], close
//   lock          lock, status   (served by the lock.qml instance)
//   notifications dismissAll, dismissLatest, toggleDnd, toggleHistory, invokeLast
//   osd           volume, brightness
//   bar           toggle, openPanel <wifi|bluetooth|audio|…>
//   center        toggle|open <calendar|theme|background>, close
ShellRoot {
  id: shell

  Bar { id: bar }
  Launcher { id: launcher; bar: bar }
  Menu { id: menu; bar: bar; onOpening: shell.closeOthers("menu") }
  Clipboard { id: clipboard }
  Keybindings { id: keybindings }
  Notifications { id: notifications }
  Osd { id: osd }

  // Overlays are mutually exclusive: opening one closes the others.
  readonly property var overlays: ({ launcher: launcher, clipboard: clipboard, menu: menu, keybindings: keybindings })

  function overlayFor(name) {
    return overlays[String(name || "")] || null
  }

  function closeOthers(name) {
    var opening = overlayFor(name)
    for (var key in overlays) {
      var other = overlays[key]
      // Launcher and command menu are states of the same DockPanel. Let the
      // host crossfade/morph them directly instead of collapsing in between.
      if (key !== name && other.opened
          && !(opening && opening.attachedPanel && other.attachedPanel)) other.close()
    }
    if (!opening || !opening.attachedPanel) Bus.dockPanelsCloseAll()
  }

  // Bar panels morph into one another, but remain exclusive with the larger
  // launcher/menu/clipboard overlays.
  Connections {
    target: Bus
    function onDockPanelRequested(panel) {
      for (var key in shell.overlays) {
        var overlay = shell.overlays[key]
        // DockPanel itself retires the old attached content. Only independent
        // overlays need closing here; closing an attached one first creates a
        // one-frame collapse/flash during launcher, menu and picker handoffs.
        if (overlay.opened && !overlay.attachedPanel) overlay.close()
      }
    }
  }

  function openOverlay(name) {
    var target = overlayFor(name)
    if (!target) return "unknown overlay: " + name
    closeOthers(name)
    target.open()
    return "ok"
  }

  function closeOverlay(name) {
    var target = overlayFor(name)
    if (!target) return "unknown overlay: " + name
    target.close()
    return "ok"
  }

  function toggleOverlay(name) {
    var target = overlayFor(name)
    if (!target) return "unknown overlay: " + name
    return target.opened ? closeOverlay(name) : openOverlay(name)
  }

  IpcHandler {
    target: "shell"
    function ping(): string { return "ok" }
    function toggle(name: string): string { return shell.toggleOverlay(name) }
    function open(name: string): string { return shell.openOverlay(name) }
    function close(name: string): string { return shell.closeOverlay(name) }
    function reloadTheme(): string { Theme.refresh(); return "ok" }
    // File-watcher reloads are disabled (see launch-shell); this is
    // the way to pick up config edits. The lock lives in another instance,
    // so a reload here can no longer drop the session lock.
    function reload(): string {
      Quickshell.reload(false)
      return "ok"
    }
  }

  // Called by shell right before it asks the lock instance to lock.
  // The menu takes a route, so it gets its own handler rather than riding on
  // the shell's name-only toggle.
  IpcHandler {
    target: "menu"
    function toggle(route: string): string { menu.toggle(route); return "ok" }
    function open(route: string): string { menu.open(route); return "ok" }
    function close(): string { menu.close(); return "ok" }
  }

  // The clock's calendar / theme / background panel.
  IpcHandler {
    target: "center"
    function toggle(mode: string): string { return bar.toggleCenter(mode) }
    function open(mode: string): string { return bar.openCenter(mode) }
    function close(): string { bar.closeCenter(); return "ok" }
  }

  IpcHandler {
    target: "overlays"
    function closeAll(): string { shell.closeOthers(""); return "ok" }
  }

  IpcHandler {
    target: "notifications"
    function dismissAll(): string { notifications.dismissAll(); return "ok" }
    function dismissLatest(): string { notifications.dismissLatest(); return "ok" }
    function toggleDnd(): string { notifications.doNotDisturb = !notifications.doNotDisturb; return notifications.doNotDisturb ? "dnd on" : "dnd off" }
    function toggleHistory(): string { notifications.toggleHistory(); return "ok" }
    function invokeLast(): string { return notifications.invokeLast() }
  }

  IpcHandler {
    target: "osd"
    function volume(): string { osd.showVolume(); return "ok" }
    function brightness(): string { osd.showBrightness(); return "ok" }
  }

  IpcHandler {
    target: "bar"
    function toggle(): string { bar.hidden = !bar.hidden; return bar.hidden ? "hidden" : "shown" }
    function openPanel(name: string): string { return bar.openPanel(name) }
  }

  Component.onCompleted: console.log("shell started, config dir " + Quickshell.shellDir)
}
