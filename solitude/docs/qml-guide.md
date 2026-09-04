# QML, Quickshell, and animating the menu

A working guide written against the code in this repo. Every example is
something you can paste into `.config/quickshell/shell` and see happen.
The last section walks through the menu's animations one at a time — they are
in `modules/menu/Menu.qml` now, so each step is something you can read in the
file next to the explanation, and change to taste.

Reload after every edit:

```bash
shell shell reload
```

File watching is off on purpose (see `launch-shell`), so nothing
happens until you ask. If the reload prints an error, the *previous* config
keeps running — a broken edit never leaves you with a dead bar. Watch what it
thought of your edit with:

```bash
journalctl --user -fu ... # or simply:
journalctl --user -n 20 --no-pager | grep -E "ERROR|WARN|Configuration"
```

That habit matters more than it sounds: a QML error is reported once, at load,
and then the shell carries on with the old code. If an edit "did nothing",
read the log before you read the file.

---

## 1. What Quickshell actually is

Quickshell is a QML runtime with Wayland desktop-shell objects bolted on. There
is no shell framework in the usual sense — no widget API to learn, no config
format. You write a QML scene, and Quickshell gives that scene the ability to
become a layer-shell surface, read the compositor's state, talk to PipeWire and
D-Bus, and be poked from the command line.

Three consequences shape everything in this directory:

**It is one long-running process.** `launch-shell` starts `qs -c
shell`, and that process holds the bar, launcher, menu, clipboard,
notification daemon and OSD at once. They are objects in one scene graph, which
is why `shell.qml` can wire them together with plain property references. The
lock screen is the exception: it runs as a *second* instance from `lock.qml`,
so that reloading the shell can never strand a locked session.

**Reload re-evaluates the QML, not the process.** `Quickshell.reload(false)`
rebuilds the scene from source. Anything you want to survive that has to live
outside the scene — a file in `Config.stateDir`, or the compositor itself. That
is why the launcher persists its usage counts and why the theme name is a file.

**The compositor is a peer, not a host.** `Quickshell.Hyprland` exposes
`focusedMonitor`, workspaces and events; `hyprctl` is available for anything the
binding does not cover. `Bar.qml` uses the first, `Theme.qml` shells out to the
second for `decoration:rounding`.

### The window types

| Type | Used for | Where |
| ---- | -------- | ----- |
| `PanelWindow` | A layer-shell surface: bar, overlay, OSD, toasts | `Bar.qml`, `Ui/Overlay.qml` |
| `PopupWindow` | A surface anchored to an item in another window | `Ui/BarPopup.qml` |
| `Variants` | One copy of a window per item in a model, usually per screen | `Bar.qml` |

`Variants` is the piece people trip over. This makes one bar per monitor:

```qml
Variants {
  id: bars
  model: Quickshell.screens

  PanelWindow {
    required property var modelData   // the screen for this copy
    screen: modelData
    anchors { left: true; right: true; top: true }
    implicitHeight: 30
    exclusiveZone: 30                 // windows are laid out below the bar
  }
}
```

`bars.instances` is the array of live copies. Because there is one per screen,
anything that acts on "the bar" has to *choose* one — and choosing wrong is
exactly the bug that made every panel open on the laptop display:

```qml
// modules/bar/Bar.qml
function barForFocus() {
  var instances = bars.instances
  if (instances.length === 0) return null
  var monitor = Hyprland.focusedMonitor
  if (monitor) {
    for (var i = 0; i < instances.length; i++) {
      var screen = instances[i].screen
      if (screen && screen.name === monitor.name) return instances[i]
    }
  }
  return instances[0]
}
```

`Ui/Overlay.qml` does the same thing for full-screen surfaces, in
`focusedScreen()`. Any new multi-monitor surface needs one of these two.

### Talking to the shell from outside

An `IpcHandler` publishes functions on a named target:

```qml
IpcHandler {
  target: "menu"
  function toggle(route: string): string { menu.toggle(route); return "ok" }
}
```

The type annotations are required — that is how the IPC layer marshals the
call. Then from anywhere:

```bash
shell menu toggle emoji
```

`shell` is a thin wrapper over `qs -c shell ipc call`. Return a
string that says what happened; `openPanel` returning `"ok on HDMI-A-1"` is how
you tell a panel that opened on the wrong screen from one that did not open.

---

## 2. QML in the amount you need

### Properties and bindings

A binding is an expression that re-evaluates itself whenever anything it read
changes. This is the whole language:

```qml
Rectangle {
  width: parent.width / 2      // re-runs when parent.width changes
  color: hovered ? Theme.hover : "transparent"
}
```

Assigning from JavaScript *destroys* the binding:

```qml
onSomething: width = 100       // width is now a dumb number forever
```

That is occasionally what you want and usually a bug. If a value needs to
change imperatively, drive it from a property the binding reads instead.

Dependency tracking is per-property and it does follow function calls, which is
what makes the theme system work:

```qml
// Commons/Theme.qml
property var palette: ({})

function themed(key, fallback) {
  var value = palette[key]
  return (typeof value === "string" && value.length > 0) ? value : fallback
}

readonly property color background: themed("background", "#101315")
```

`background` read `palette` while evaluating, so replacing `palette` repaints
every surface bound to `Theme.background`. Nothing subscribes, nothing
refreshes.

The catch is that tracking is per-*property*, not per-element-of-object.
Mutating `palette.background = "#fff"` in place changes nothing on screen,
because `palette` itself never changed. Always assign a new object:

```qml
var next = JSON.parse(text())
root.palette = next            // yes
// root.palette.accent = "#f00"   // no
```

Types worth knowing: `int`, `real`, `string`, `bool`, `color`, `var` (any JS
value), `list<T>`, and any QML type by name (`property FileView nameFile:
FileView { ... }`). `readonly property` is a binding that cannot be assigned
over — use it for anything derived.

### Signals

Every property gets a change signal automatically. Handlers are named
`on<Property>Changed`:

```qml
property string filter: ""
onFilterChanged: selectedIndex = 0
```

Declare your own with `signal`, and handle it where the object is used:

```qml
// modules/menu/Menu.qml
signal opening()

// shell.qml
Menu { id: menu; onOpening: shell.closeOthers("menu") }
```

That pattern — the child announces, the parent decides — is why `Menu.qml` does
not know the other overlays exist.

For talking *up* past a parent that is not there (a bar widget reaching the
overlays next to the shell root), this repo uses a singleton as a signal bus:

```qml
// Commons/Bus.qml
pragma Singleton
QtObject { signal menuRequested(string route) }

// modules/bar/widgets/Clock.qml
onClicked: Bus.menuRequested("root")

// modules/menu/Menu.qml
Connections {
  target: Bus
  function onMenuRequested(route) { root.toggle(route) }
}
```

`Connections` is how you attach a handler to an object you did not declare.
Note the handler is a *function* named `on<Signal>`, not a property.

A singleton needs `pragma Singleton` at the top of the file and a line in the
directory's `qmldir`:

```
singleton Bus 1.0 Bus.qml
```

Forgetting the `qmldir` line is the most common "Type Bus unavailable" error.

### Layout

Three mechanisms, and mixing them on one item is a mistake:

- **`anchors`** — glue edges to another item's edges. `anchors.fill: parent`,
  `anchors.centerIn: parent`, `anchors.left: parent.left`.
- **Layouts** (`RowLayout`, `ColumnLayout`) — items get sized by the layout;
  children use `Layout.fillWidth`, `Layout.preferredHeight`. Never anchor a
  child that is inside a layout.
- **Manual `x`/`y`/`width`/`height`** — what the menu card uses, because it
  positions itself against the bar:

```qml
Card {
  width: root.cfg.width
  x: Math.round((parent.width - width) / 2)
  y: Config.bar.height + Theme.space
  height: header.implicitHeight + separator.height + body.height + Theme.spaceSm * 2
}
```

`implicitWidth`/`implicitHeight` are an item's natural size; a layout or a
parent reads them. Setting `height` explicitly overrides the implicit one.

### Lists

`ListView` + `delegate` renders a model. The model here is a plain JS array,
which is enough for a few hundred rows:

```qml
ListView {
  model: root.rows                 // array of objects
  currentIndex: root.selectedIndex
  clip: true                       // stop rows painting outside the view

  delegate: Rectangle {
    required property int index
    required property var modelData
    width: ListView.view.width
    height: 44
    Text { text: parent.modelData.title }
  }
}
```

`required property var modelData` is the modern spelling; without `required`
you get the older implicit-context behaviour that silently shadows names.
`clip: true` is not optional on a scrolling list inside a rounded card.

### Processes and files

```qml
Process {
  id: generator
  command: ["theme", "list"]
  running: true
  stdout: StdioCollector {
    onStreamFinished: root.rows = parse(text)
  }
}
```

`command` is an argv array — no shell, no quoting bugs. When you genuinely want
a shell line, be explicit: `["bash", "-lc", line]`, which is what `Util.exec`
does. `Util.execArgv` is the argv equivalent for launching something detached.

`FileView` reads a file and can watch it:

```qml
property FileView nameFile: FileView {
  path: Config.stateDir + "/theme"
  watchChanges: true
  printErrors: false
  onFileChanged: reload()
  onLoaded: root.themeName = String(text()).trim() || "solitude"
  onLoadFailed: root.themeName = "solitude"
}
```

`onFileChanged: reload()` is required — watching tells you the file moved, it
does not re-read it for you. Always handle `onLoadFailed`; a missing file is
normal on a fresh install.

---

## 3. How this shell is put together

```
shell.qml                     root: instantiates modules, exposes IPC
Commons/Config.qml            all user settings (singleton)
Commons/Theme.qml             palette + spacing tokens (singleton)
Commons/Util.qml              pure helpers (singleton)
Commons/Bus.qml               widget -> overlay signals (singleton)
Ui/                           Overlay, Card, SearchField, BarPopup, ...
modules/bar/                  Bar.qml + WidgetSlot.qml + widgets/ + panels/
modules/menu/                 Menu.qml + Routes.js
modules/launcher/ clipboard/ keybindings/ notifications/ osd/ lock/ displays/
```

The bar is worth tracing once, because it is the pattern the rest follow:
`Config.bar.right` is a list of widget *ids*; `Bar.qml` repeats a `WidgetSlot`
over that list; `WidgetSlot.qml` maps an id to a `Component`. Adding a widget
is a `Component` line plus a registry entry — no `Bar.qml` edit.

`modules/menu` splits the same way, one level up: `Routes.js` is data, and
`Menu.qml` never names a route. The root route is one flat list of actions;
a row is:

```js
{ glyph: "󰉦", title: "Theme",   subtitle: "…", route: "theme" }     // push a picker
{ glyph: "󰨏", title: "Shot",    command: "screenshot" }    // shell line
{ glyph: "󰌾", title: "Lock",    argv: ["shell","lock","lock"] }
{ glyph: "󰅍", title: "Copy",    copy: "text" }                     // clipboard
```

plus `requires: "<command>"` to hide a row when the command is not installed,
and generator routes that build their rows from a script's stdout:

```js
theme: {
  title: "Theme",
  view: "grid",
  generator: ["theme", "list"],
  run: ["theme", "set", "$PAYLOAD"]
}
```

The script prints `glyph<TAB>title<TAB>payload<TAB>subtitle<TAB>image`, and
`$PAYLOAD` is substituted as a single argv element — a wallpaper path with a
space in it cannot turn into two arguments.

The theme and background pickers use the same row format but render as
carousels in the clock's center panel (`modules/bar/center/Carousel.qml`),
a second example of the same data driving a different layout. Two details
there generalise:

```qml
// A string is not a bool. QML refuses the assignment and warns at runtime.
visible: !!tile.modelData.image && status === Image.Ready

// Decode at tile size, not at the file's 2880px.
sourceSize.width: Math.round(tiles.cellWidth)
fillMode: Image.PreserveAspectCrop
asynchronous: true
```

`sourceSize` is the one that matters: without it every tile holds a
full-resolution decoded image in memory.

---

## 4. Animation

### The four tools

**`Behavior`** — "whenever this property changes, get there over time". This is
the one you want nine times out of ten, because it needs no trigger:

```qml
Rectangle {
  color: hovered ? Theme.hover : "transparent"
  Behavior on color { ColorAnimation { duration: 120 } }
}
```

**`NumberAnimation` / `ColorAnimation` / `PropertyAnimation`** — an animation
object. Inside a `Behavior` it needs no target. Standalone it needs `target`,
`property`, `from`/`to`, and something to `start()` it.

**`SequentialAnimation` / `ParallelAnimation`** — containers. A `PauseAnimation`
inside a sequence is how you stagger.

**States and `Transition`s** — a named set of property values plus rules for
moving between them. Worth it when an element has three or more distinct looks;
overkill for open/closed.

Easing is set per animation: `easing.type: Easing.OutCubic` decelerates into
place and is the right default for something appearing. `Easing.InOutQuad` for
something moving between two on-screen positions. `Easing.OutBack` overshoots
slightly — nice on a small element, silly on a whole panel.

Durations: 120–180 ms for a panel, 80–120 ms for a hover or selection. Past
250 ms a shell feels slow no matter how pretty the curve.

### Walkthrough: the menu's animations

These five steps are how `modules/menu/Menu.qml` got its animations, in the
order they were added. Each one is in the file — open it alongside this, and
change the numbers to see what each does. Reload after every edit.

**Step 1 — fade and drop the card in.**

The card is at `Card { id: card }`. `root.opened` is the open/closed flag:

```qml
        opacity: root.opened ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        transform: Translate {
          y: root.opened ? 0 : -Theme.spaceXl
          Behavior on y {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
          }
        }
```

Two things to notice. First, `transform: Translate` moves the item *visually*
without touching `y`, so the layout expression above it (`y: Config.bar.height
+ Theme.space`) stays a clean binding — animating `y` directly would fight it.
Second, on its own this fades *in* only: the `Overlay`'s surface used to follow
`opened` directly, so on close it vanished before the animation could play.
Step 4 is what fixed that.

The duration comes from `Config.menu.animationMs` rather than a literal, so one
number tunes the whole menu. Try 400 to watch each step clearly, then put it
back.

**Step 2 — smooth the height change.**

The card's `height` binding changes whenever a route has a different number of
rows. Because it is a binding, a `Behavior` is all it takes:

```qml
        Behavior on height {
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
```

Try it with `Super+Escape` (5 rows) then `Super+E` (a long list). If it looks
jumpy, the cause is the row count changing in the same frame as the filter —
lower the duration rather than reaching for a state machine.

**Step 3 — slide a route in from the side it came from.**

`root.slide` is `-1` after `push()` and `+1` after `pop()`. Inside the
`ListView` (and the same again in the `GridView`):

```qml
              transform: Translate { id: listSlide }
              onModelChanged: if (!root.grid && root.slide !== 0) listSlideIn.restart()

              NumberAnimation {
                id: listSlideIn
                target: listSlide
                property: "x"
                from: root.slide * root.cfg.slidePx
                to: 0
                duration: root.cfg.animationMs
                easing.type: Easing.OutCubic
              }
```

This is the standalone form of an animation: it has a `target` and a
`property`, and `restart()` fires it. `onModelChanged` is the trigger, because
`rows` is recomputed on every route change.

Why a `Translate` again rather than animating `list.x`: both views are
`anchors.fill: parent`, and an anchored item's `x` belongs to the anchor
layout. Animating it is a fight you lose silently — the value gets overwritten
on the next layout pass. A transform is pure paint and nothing else touches it.

The `root.slide !== 0` guard matters: the model also goes from empty to full on
the first open, and without it every fresh open slides. `open()` resets `slide`
to 0 for exactly this.

**Step 4 — make the close animate too.**

Binding `Overlay.opened` straight to `opened` makes closing instant: the layer
surface is torn down in the same frame the fade starts. The fix is to separate
"is the menu logically open" from "is the surface up":

```qml
  property bool surfaceUp: false

  function open(target) {
    // ...
    closeTimer.stop()        // an open during a close cancels the teardown
    surfaceUp = true
    opened = true
  }

  function close() {
    opened = false
    closeTimer.restart()     // let the fade play, then drop the surface
    // ... existing cleanup
  }

  Timer {
    id: closeTimer
    interval: root.cfg.animationMs + 40   // outlast the animation
    onTriggered: root.surfaceUp = false
  }

  Overlay {
    opened: root.surfaceUp
  }
```

`closeTimer.stop()` in `open()` is not optional: reopening inside the closing
window would otherwise let the old timer fire and pull the surface out from
under the new one.

This is the general shape of every "animate out" problem in a compositor shell
— the surface must outlive the animation. You can watch it work with `grim`:
screenshot right after `menu close` and the card is still there, screenshot a
second later and it is gone.

**Step 5 — stagger the rows.**

`ListView` has `add` and `populate` transitions:

```qml
              populate: Transition {
                NumberAnimation {
                  property: "opacity"; from: 0; to: 1
                  duration: 120; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                  property: "y"; from: 8; to: 0
                  duration: 120; easing.type: Easing.OutCubic
                }
              }
```

Genuine per-row stagger needs `ViewTransition.index` and a `PauseAnimation`:

```qml
              populate: Transition {
                SequentialAnimation {
                  PauseAnimation {
                    duration: Math.max(0, Math.min(ViewTransition.index * 12, 120))
                  }
                  NumberAnimation {
                    property: "opacity"; from: 0; to: 1
                    duration: root.cfg.animationMs; easing.type: Easing.OutCubic
                  }
                }
              }
```

Both clamps are load-bearing. `Math.min` caps the delay — without it, opening
the 1810-row emoji list queues a 36-second animation. `Math.max(0, …)` handles
`ViewTransition.index` being `-1` when the attached property is evaluated
outside a running transition, which QML reports as
`QML PauseAnimation: Cannot set a duration of < 0` once per row.

### Things that will bite you

- **Animating a property that drives layout.** A `Behavior` on `width` inside a
  `RowLayout` fights the layout every frame. Animate `opacity`, `scale`, or a
  `transform` instead — those are pure paint.
- **`visible: false` kills animations.** A hidden item does not animate, and it
  cannot animate *itself* back into view. Use `opacity` for anything that
  animates, and toggle `visible` only after (Step 4).
- **Binding loops.** If an animated property is also read by the expression
  that sets it, QML warns `Binding loop detected` and gives up. Break it with a
  second property.
- **Animations on load.** Everything animates from its default value at
  startup, so a shell can visibly assemble itself on reload. Guard with a flag
  set in `Component.onCompleted`, or animate only properties whose default is
  already the resting value.
- **`Behavior` inside `Behavior`.** Legal, does nothing useful, silently
  ignores the inner one.

### Checking your work

There is no visual debugger here, so use the same loop the rest of this repo
uses:

```bash
shell shell reload
journalctl --user -n 20 --no-pager | grep -E "ERROR|WARN"
shell menu open emoji     # exercise the thing you changed
shell menu close
```

`WARN scene: @modules/menu/Menu.qml[52:-1]: TypeError: …` gives you file and
line. `ERROR: Failed to load configuration` means your edit did not load at all
and you are still looking at the old shell — the reason it is usually right
below, as `caused by`.

---

## 5. Where to go next

- Quickshell types: <https://quickshell.org/docs/>
- Qt Quick elements and the animation framework:
  <https://doc.qt.io/qt-6/qtquick-index.html>
- The two files most worth reading in this repo before writing your own module:
  `modules/menu/Menu.qml` (overlay, keyboard handling, generator processes) and
  `modules/bar/Bar.qml` (per-screen windows, focus selection).
