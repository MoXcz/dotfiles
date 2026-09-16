import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.Commons
import qs.Ui

// Notification daemon: stacked toast popups in one screen corner plus an
// in-memory history overlay. Toast rows hold plain copies of the
// notification content; the live Notification objects are kept in `live`
// keyed by id so actions can still be invoked and the server informed of
// dismissals.
Item {
  id: root

  property bool doNotDisturb: false
  property bool historyOpen: false

  readonly property var cfg: Config.notifications
  readonly property bool topCorner: cfg.corner.indexOf("top") === 0
  readonly property bool leftCorner: cfg.corner.indexOf("left") >= 0

  property var live: ({})
  property var queue: []

  ListModel { id: toasts }
  ListModel { id: history }

  // ---------------------------------------------------------------- server

  NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    imageSupported: true
    persistenceSupported: true
    onNotification: function(notification) { root.receive(notification) }
  }

  function receive(n) {
    remember(n)
    if (root.doNotDisturb) return
    n.tracked = true
    var id = n.id
    live[id] = n
    n.closed.connect(function() { root.forget(id) })
    if (toasts.count < cfg.maxVisible) show(n)
    else queue.push(n)
  }

  function remember(n) {
    history.insert(0, {
      app: String(n.appName || ""),
      summary: String(n.summary || ""),
      body: String(n.body || ""),
      time: Qt.formatTime(new Date(), "HH:mm")
    })
    while (history.count > cfg.historyLimit) history.remove(history.count - 1)
  }

  function show(n) {
    var actions = []
    for (var i = 0; i < n.actions.length; i++) {
      actions.push({ label: String(n.actions[i].text || ""), idx: i })
    }
    var row = {
      nid: n.id,
      app: String(n.appName || ""),
      summary: String(n.summary || ""),
      body: String(n.body || ""),
      icon: iconSource(n.image) || iconSource(n.appIcon),
      critical: n.urgency === NotificationUrgency.Critical,
      actions: actions
    }
    if (toasts.count === 0) popup.screen = focusedScreen()
    // Newest sits nearest the anchored edge.
    if (root.topCorner) toasts.insert(0, row)
    else toasts.append(row)
  }

  function iconSource(value) {
    var s = String(value || "")
    if (s.length === 0) return ""
    if (s.indexOf("file://") === 0 || s.indexOf("image://") === 0) return s
    if (s.charAt(0) === "/") return Util.fileUrl(s)
    return Quickshell.iconPath(s, true)
  }

  function rowOf(id) {
    for (var i = 0; i < toasts.count; i++) {
      if (toasts.get(i).nid === id) return i
    }
    return -1
  }

  // Called from the notification's closed signal: the object is about to be
  // destroyed, so only drop our references and refill from the queue.
  function forget(id) {
    delete live[id]
    var row = rowOf(id)
    if (row >= 0) toasts.remove(row)
    for (var i = queue.length - 1; i >= 0; i--) {
      if (queue[i].id === id) queue.splice(i, 1)
    }
    drain()
  }

  function drain() {
    while (queue.length > 0 && toasts.count < cfg.maxVisible) show(queue.shift())
  }

  function dismiss(id) {
    var n = live[id]
    if (n) n.dismiss()
    else forget(id)
  }

  function expire(id) {
    var n = live[id]
    if (n) n.expire()
    else forget(id)
  }

  function invoke(id, index) {
    var n = live[id]
    if (!n || index < 0 || index >= n.actions.length) return
    n.actions[index].invoke()
  }

  function invokeDefault(id) {
    var n = live[id]
    if (!n) return
    for (var i = 0; i < n.actions.length; i++) {
      if (n.actions[i].identifier === "default") { n.actions[i].invoke(); return }
    }
  }

  // ---------------------------------------------------------------- public

  function dismissAll() {
    queue = []
    var ids = []
    for (var i = 0; i < toasts.count; i++) ids.push(toasts.get(i).nid)
    ids.forEach(dismiss)
  }

  function dismissLatest() {
    if (toasts.count === 0) return
    dismiss(toasts.get(root.topCorner ? 0 : toasts.count - 1).nid)
  }

  // Fire the newest toast's default action, the same thing clicking it does.
  // Reports back so the caller can tell "nothing there" from "nothing to run".
  function invokeLast() {
    if (toasts.count === 0) return "no notifications"
    var id = toasts.get(root.topCorner ? 0 : toasts.count - 1).nid
    var n = live[id]
    if (!n) return "notification is gone"
    for (var i = 0; i < n.actions.length; i++) {
      if (n.actions[i].identifier === "default") { n.actions[i].invoke(); return "ok" }
    }
    // No default action: the first one is what a click would have offered.
    if (n.actions.length > 0) { n.actions[0].invoke(); return "ok" }
    return "no action on the last notification"
  }

  function toggleHistory() {
    historyOpen = !historyOpen
  }

  function focusedScreen() {
    var monitor = Hyprland.focusedMonitor
    var screens = Quickshell.screens
    if (monitor) {
      for (var i = 0; i < screens.length; i++) {
        if (screens[i].name === monitor.name) return screens[i]
      }
    }
    return screens.length > 0 ? screens[0] : null
  }

  // ---------------------------------------------------------------- popups

  PanelWindow {
    id: popup
    visible: toasts.count > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "shell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
      top: root.topCorner
      bottom: !root.topCorner
      left: root.leftCorner
      right: !root.leftCorner
    }
    margins {
      // Top notifications begin below the unified bar, sharing its right
      // alignment instead of appearing as an unrelated corner overlay.
      top: root.topCorner ? Config.bar.height + Theme.spaceSm : root.cfg.margin
      bottom: root.cfg.margin
      left: root.cfg.margin
      right: root.topCorner && !root.leftCorner ? Config.bar.marginX : root.cfg.margin
    }
    implicitWidth: root.cfg.width
    implicitHeight: Math.max(1, column.implicitHeight)

    Column {
      id: column
      width: parent.width
      spacing: Theme.space

      Repeater {
        model: toasts

        delegate: Card {
          id: toast
          required property int nid
          required property string app
          required property string summary
          required property string body
          required property string icon
          required property bool critical
          required property var actions

          width: column.width
          implicitHeight: content.implicitHeight + Theme.spaceLg * 2
          border.color: critical ? Theme.urgent : Theme.border

          opacity: 0
          x: root.leftCorner ? -Theme.spaceXl : Theme.spaceXl
          Component.onCompleted: { opacity = 1; x = 0 }
          Behavior on opacity { NumberAnimation { duration: 160 } }
          Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

          HoverHandler { id: hover }

          Timer {
            interval: toast.critical ? root.cfg.criticalTimeoutMs : root.cfg.timeoutMs
            running: interval > 0 && !hover.hovered
            onTriggered: root.expire(toast.nid)
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: function(mouse) {
              if (mouse.button === Qt.MiddleButton) root.dismiss(toast.nid)
              else root.invokeDefault(toast.nid)
            }
          }

          Row {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceLg }
            spacing: Theme.space

            IconImage {
              visible: toast.icon.length > 0
              source: toast.icon
              implicitSize: Theme.fontTitle * 2
              anchors.top: parent.top
            }

            Column {
              width: parent.width - (toast.icon.length > 0 ? Theme.fontTitle * 2 + Theme.space : 0)
              spacing: Theme.spaceSm

              Row {
                width: parent.width
                spacing: Theme.space

                Column {
                  width: parent.width - closeButton.width - Theme.space
                  spacing: 2

                  Text {
                    width: parent.width
                    visible: toast.app.length > 0
                    text: toast.app
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: toast.summary
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }
                }

                Text {
                  id: closeButton
                  text: "󰅖"
                  color: closeArea.containsMouse ? Theme.foreground : Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontIcon
                  MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -Theme.spaceSm
                    hoverEnabled: true
                    onClicked: root.dismiss(toast.nid)
                  }
                }
              }

              Text {
                width: parent.width
                visible: toast.body.length > 0
                text: toast.body
                textFormat: Text.StyledText
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                onLinkActivated: function(link) { Qt.openUrlExternally(link) }
              }

              Flow {
                width: parent.width
                spacing: Theme.spaceSm
                visible: toast.actions.count > 0

                Repeater {
                  model: toast.actions

                  delegate: Rectangle {
                    id: actionButton
                    required property string label
                    required property int idx
                    width: actionLabel.implicitWidth + Theme.space * 2
                    height: actionLabel.implicitHeight + Theme.spaceSm * 2
                    radius: Theme.cornerRadius
                    color: actionArea.containsMouse ? Theme.selected : Theme.surfaceAlt
                    border.color: Theme.border
                    border.width: Theme.borderWidth

                    Text {
                      id: actionLabel
                      anchors.centerIn: parent
                      text: actionButton.label
                      color: Theme.foreground
                      font.family: Theme.fontFamily
                      font.pixelSize: Theme.fontBody
                    }

                    MouseArea {
                      id: actionArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onClicked: root.invoke(toast.nid, actionButton.idx)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------- history

  Overlay {
    id: historyOverlay
    namespace: "shell-notification-history"
    opened: root.historyOpen
    onDismissed: root.historyOpen = false
    onOpenedChanged: if (opened) keys.forceActiveFocus()

    Item {
      id: keys
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(event) {
        var step = list.height / 2
        switch (event.key) {
        case Qt.Key_Escape: root.historyOpen = false; break
        case Qt.Key_Delete: history.clear(); break
        case Qt.Key_Down: case Qt.Key_J: case Qt.Key_N: list.contentY = Math.min(list.contentY + step, Math.max(0, list.contentHeight - list.height)); break
        case Qt.Key_Up: case Qt.Key_K: case Qt.Key_P: list.contentY = Math.max(0, list.contentY - step); break
        default: return
        }
        event.accepted = true
      }

      Card {
        anchors.centerIn: parent
        width: Math.min(560, parent.width - Theme.spaceXl * 2)
        height: Math.min(parent.height * 0.7, Theme.spaceLg * 2 + header.implicitHeight + Theme.space + Math.max(list.contentHeight, 80))

        // Clicks inside the card must not reach the scrim.
        MouseArea { anchors.fill: parent }

        Row {
          id: header
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceLg }
          spacing: Theme.space

          Text {
            id: historyTitle
            text: "Notifications"
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontHeading
            font.bold: true
          }
          Text {
            anchors.baseline: historyTitle.baseline
            text: history.count > 0 ? history.count + "  ·  Delete clears" : "empty"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
          }
        }

        ListView {
          id: list
          anchors { left: parent.left; right: parent.right; bottom: parent.bottom; top: header.bottom }
          anchors.margins: Theme.spaceLg
          anchors.topMargin: Theme.space
          clip: true
          model: history
          spacing: Theme.spaceSm
          Behavior on contentY { NumberAnimation { duration: 80 } }

          delegate: Rectangle {
            required property string app
            required property string summary
            required property string body
            required property string time
            width: list.width
            height: entry.implicitHeight + Theme.space * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceAlt

            Column {
              id: entry
              anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space }
              spacing: 2

              Row {
                width: parent.width
                Text {
                  width: parent.width - timeLabel.width
                  text: (app.length > 0 ? app + "  " : "") + summary
                  color: Theme.foreground
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontBody
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  id: timeLabel
                  text: time
                  color: Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: Theme.fontCaption
                }
              }

              Text {
                width: parent.width
                visible: body.length > 0
                text: body
                textFormat: Text.StyledText
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
              }
            }
          }
        }
      }
    }
  }
}
