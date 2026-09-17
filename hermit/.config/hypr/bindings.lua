local mod = "SUPER"
local modAlt = mod .. " + ALT"
local modShift = mod .. " + SHIFT"
local modCtrl = mod .. " + CTRL"
local modShiftAlt = modShift .. " + ALT"
local modShiftCtrl = modShift .. " + CTRL"
local modCtrlAlt = modCtrl .. " + ALT"

local terminal = "kitty"
local explorer = "nemo"

-- ─── Application bindings ─────────────────────
o.bind(mod .. " + RETURN", "Terminal", o.launch(terminal))
o.bind(mod .. " + N", "File manager", o.launch(explorer))
o.bind(mod .. " + T", "Activity", { tui = "btop" })
o.bind(mod .. " + O", "Obsidian", o.launch("obsidian"))

-- ─── Menus ─────────────────────
o.bind(mod .. " + D", "Launch apps", "menu launcher")
o.bind(modShift .. " + D", "Command menu", "menu")
o.bind(mod .. " + E", "Emoji picker", "menu emoji")
o.bind(modCtrl .. " + K", "Search key bindings", "menu keybindings")
o.bind(modCtrl .. " + PERIOD", "Transcode", "transcode")
o.bind(modCtrl .. " + SPACE", "Background switcher", "menu background")
o.bind(modShiftCtrl .. " + SPACE", "Theme switcher", "menu theme")
o.bind(modAlt .. " + K", "Keyboard layout menu", "menu keyboard")
o.bind("XF86Calculator", "Calculator", "gnome-calculator")

-- ─── Aesthetics ─────────────────────
o.bind(modShift .. " + SPACE", "Toggle top bar", "pkill -SIGUSR1 waybar")
o.bind(mod .. " + BACKSPACE", "Toggle window transparency",
  hl.dsp.window.set_prop({ window = "active", prop = "opaque", value = "toggle" }))

-- ─── Window bindings ─────────────────────
o.bind(mod .. " + Q", "Close window", hl.dsp.window.close())
o.bind(mod .. " + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind(mod .. " + I", "Pseudo window", hl.dsp.window.pseudo())
o.bind(mod .. " + SPACE", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind(mod .. " + P", "Move workspace to next monitor", hl.dsp.workspace.move({ monitor = -1 }))
o.bind(mod .. " + S", "Toggle window split", hl.dsp.layout("togglesplit"))

-- Focus Movement
o.bind(mod .. " + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind(mod .. " + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind(mod .. " + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind(mod .. " + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))

-- Move Windows
o.bind(modShift .. " + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind(modShift .. " + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind(modShift .. " + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind(modShift .. " + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

-- ─── Groups ──────────────────────────────
o.bind(mod .. " + G", "Toggle window grouping", hl.dsp.group.toggle())
o.bind(modAlt .. " + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))
o.bind(mod .. " + TAB", "Next window in group", hl.dsp.group.next())
o.bind(modShift .. " + TAB", "Previous window in group", hl.dsp.group.prev())

-- ─── Workspaces ──────────────────────────────
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind(mod .. " + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind(modShift .. " + " .. key, "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind(modShiftAlt .. " + " .. key, "Move window silently to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

-- ─── Resize ──────────────────────────────────
o.bind(mod .. " + R", "Enter resize mode", hl.dsp.submap("resize"))
o.bind(mod .. " + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind(mod .. " + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

hl.define_submap("resize", function()
  hl.bind("L", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
  hl.bind("H", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
  hl.bind("J", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
  hl.bind("K", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })

  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- ─── Media ──────────────────────────────────
o.bind("XF86AudioRaiseVolume", "Volume up", "swayosd-client --output-volume raise",
  { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "swayosd-client --output-volume lower",
  { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "swayosd-client --output-volume mute-toggle", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", "swayosd-client --input-volume mute-toggle", { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", "swayosd-client --brightness raise",
  { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "swayosd-client --brightness lower",
  { locked = true, repeating = true })
o.bind(modShift .. " + XF86MonBrightnessUp", "Brightness maximum",
  "swayosd-client --brightness 100", { locked = true })
o.bind(modShift .. " + XF86MonBrightnessDown", "Brightness minimum",
  "swayosd-client --brightness 1", { locked = true })

local kbd_backlight =
"bash -c 'd=$(basename $(ls -d /sys/class/leds/*kbd_backlight* 2>/dev/null | head -1)) && brightnessctl -d \"$d\" set "
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", kbd_backlight .. "10%+'",
  { locked = true, repeating = true })
o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", kbd_backlight .. "10%-'",
  { locked = true, repeating = true })

-- Precise 1% multimedia adjustments with Alt modifier
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "swayosd-client --output-volume +1",
  { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "swayosd-client --output-volume -1",
  { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "swayosd-client --brightness +1",
  { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise",
  "swayosd-client --brightness -1", { locked = true, repeating = true })

-- Requires playerctl
o.bind("XF86AudioNext", "Next track", "playerctl next", { locked = true })
o.bind("XF86AudioPause", "Pause", "playerctl play-pause", { locked = true })
o.bind("XF86AudioPlay", "Play", "playerctl play-pause", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "playerctl previous", { locked = true })

-- omarchy-audio-output-switch, inlined without jq: rotate to the next sink.
o.bind(mod .. " + XF86AudioMute", "Switch audio output",
  "bash -c 'cur=$(pactl get-default-sink); " ..
  "next=$(pactl list short sinks | cut -f2 | awk -v c=\"$cur\" " ..
  "\"{n[NR]=\\$0} END {for (i=1; i<=NR; i++) if (n[i]==c) {print n[i%NR+1]; exit} print n[1]}\"); " ..
  "[ -n \"$next\" ] && pactl set-default-sink \"$next\" && notify-send -u low \"Audio output: $next\"'",
  { locked = true })

-- ─── Notifications ─────────────────────
o.bind(mod .. " + COMMA", "Dismiss last notification", "makoctl dismiss")
o.bind(modShift .. " + COMMA", "Dismiss all notifications", "makoctl dismiss --all")
o.bind(modCtrl .. " + COMMA", "Toggle silencing notifications", "toggle dnd")
o.bind(modAlt .. " + COMMA", "Invoke last notification", "makoctl invoke")
o.bind(modShiftAlt .. " + COMMA", "Restore last dismissed notification", "makoctl restore")

-- ─── Captures ─────────────────────
o.bind("PRINT", "Screenshot", "screenshot")
o.bind(modShift .. " + S", "Screenshot", "screenshot")
o.bind("ALT + PRINT", "Screen recording", "screenrecord")
o.bind(mod .. " + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind(modCtrl .. " + PRINT", "Extract text (OCR) from screenshot", "ocr")

-- Control panels: TUIs in a floating terminal (see `tui`)
o.bind(mod .. " + A", "Audio controls", "tui wiremix")
o.bind(mod .. " + B", "Bluetooth controls", "tui bluetui")
o.bind(mod .. " + W", "Wifi controls", "tui nmtui")
o.bind(mod .. " + S", "System usage", "tui btop")

-- Zoom
o.bind(modCtrl .. " + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
o.bind(modCtrlAlt .. " + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Lock system
o.bind(modCtrl .. " + L", "Lock system", "lock")
o.bind(modShift .. " + Q", "Power menu", "menu power")

-- Clipboard
o.bind(mod .. " + C", "Clipboard manager", "clipboard")
