import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Commons

// Session lock: an ext_session_lock_v1 surface per screen backed by PAM.
// All state lives here; LockSurface is a dumb view bound to this item so
// typing on any monitor edits the same password.
Item {
  id: root

  readonly property bool locked: sessionLock.locked
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

  property string password: ""
  property bool authenticating: false
  property bool failed: false
  property int attempts: 0
  readonly property string status: authenticating ? "Authenticating…"
                                 : failed ? (attempts > 1 ? "Wrong password (" + attempts + ")" : "Wrong password")
                                 : ""

  // Emitted on every failed attempt so surfaces can play their shake animation.
  signal failure()

  function lock() {
    if (sessionLock.locked) return
    reset()
    attempts = 0
    sessionLock.locked = true
  }

  function reset() {
    password = ""
    authenticating = false
    failed = false
    if (pam.active) pam.abort()
  }

  function submit() {
    if (!sessionLock.locked || authenticating || pam.active) return
    if (password.length === 0) return
    authenticating = true
    failed = false
    if (!pam.start()) fail()
  }

  function fail() {
    if (!sessionLock.locked) return
    authenticating = false
    password = ""
    attempts += 1
    failed = true
    failure()
  }

  function unlock() {
    sessionLock.locked = false
    reset()
  }

  // Survives Quickshell reloads. If the tree is rebuilt while locked, lock
  // again immediately so Hyprland's lock-restore hands the session back to us.
  PersistentProperties {
    id: persist
    reloadableId: "shell-lock"
    property bool wasLocked: false
    onReloaded: if (wasLocked) root.lock()
  }

  onLockedChanged: persist.wasLocked = locked

  WlSessionLock {
    id: sessionLock

    WlSessionLockSurface {
      color: Theme.background

      LockSurface {
        anchors.fill: parent
        lock: root
      }
    }
  }

  PamContext {
    id: pam
    config: Config.lock.pamConfig
    user: root.userName

    // The password is the answer to whatever prompt the stack asks for; a
    // conversation with several prompts gets the same answer each time.
    onPamMessage: {
      if (responseRequired && root.authenticating) respond(root.password)
    }

    onCompleted: function(result) {
      if (result === PamResult.Success) root.unlock()
      else root.fail()
    }

    onError: function(error) {
      // completed(PamResult.Error) follows; nothing else to do here.
      console.warn("lock: pam error " + error)
    }
  }
}
