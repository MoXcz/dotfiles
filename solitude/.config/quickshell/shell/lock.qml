import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "modules/lock"

// session lock shell, never reloaded like the bar and menu shell.
ShellRoot {
  id: shell

  Lock { id: lock }

  IpcHandler {
    target: "lock"
    function lock(): string { lock.lock(); return "ok" }
    function status(): string { return lock.locked ? "locked" : "unlocked" }
  }

  IpcHandler {
    target: "shell"
    function ping(): string { return "ok" }
  }

  Component.onCompleted: console.log("lock started")
}
