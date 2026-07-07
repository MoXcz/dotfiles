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
o.bind_menu(modCtrl .. " + S", "Share", "share")
o.bind(modCtrl .. " + PERIOD", "Transcode", hl.dsp.exec_cmd("omarchy-transcode"))

-- ─── Menus ─────────────────────
o.bind(mod .. " + D", "Launch apps", { omarchy = "walker" })
o.bind(mod .. " + E", "Emoji picker", { omarchy = "walker -m symbols" })
o.bind_menu(modCtrl .. " + O", "Toggle menu", "toggle")
o.bind_menu(modCtrl .. " + H", "Hardware menu", "hardware")
o.bind_menu(modAlt .. " + SPACE", "Omarchy menu", nil)
o.bind_menu(mod .. " + ESCAPE", "System menu", "system")
o.bind_menu("XF86PowerOff", "Power menu", "system", { locked = true })
o.bind(modCtrl .. " + K", "Show key bindings", hl.dsp.exec_cmd("omarchy-menu-keybindings"))
o.bind("XF86Calculator", "Calculator", hl.dsp.exec_cmd("gnome-calculator"))

-- ─── Aesthetics ─────────────────────
o.bind(modShift .. " + SPACE", "Toggle top bar", hl.dsp.exec_cmd("omarchy-toggle-waybar"))
o.bind_menu(modCtrl .. " + SPACE", "Background switcher", "background")
o.bind_menu(modShiftCtrl .. " + SPACE", "Theme menu", "theme")
o.bind(mod .. " + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")
o.bind(modShift .. " + BACKSPACE", "Toggle window gaps", "omarchy-hyprland-window-gaps-toggle")
o.bind(modCtrl .. " + BACKSPACE", "Toggle single-window square aspect",
  hl.dsp.exec_cmd("omarchy-hyprland-window-single-square-aspect-toggle"))

-- ─── Window bindings ─────────────────────
o.bind(mod .. " + Q", "Close window", hl.dsp.window.close())
o.bind(mod .. " + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind(mod .. " + I", "Pseudo window", hl.dsp.window.pseudo())
o.bind(mod .. " + SPACE", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind(mod .. " + P", "Move workspace to next monitor", hl.dsp.workspace.move({ monitor = -1 }))
o.bind(mod .. " + S", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind(modAlt .. " + L", "Toggle workspace layout", hl.dsp.exec_cmd("omarchy-hyprland-workspace-layout-toggle"))

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
-- Switch workspaces with SUPER + [1-9; 0]
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind(mod .. " + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind(modShift .. " + " .. key, "Move window to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind(modShiftAlt .. " + " .. key, "Move window silently to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

-- ─── Monitor ──────────────────────────────────
-- Cycle monitor scaling with SUPER + /
o.bind(mod .. " + code:61", "Cycle monitor scaling", hl.dsp.exec_cmd("omarchy-hyprland-monitor-scaling-cycle"))
o.bind(modAlt .. " + code:61", "Cycle monitor scaling backwards",
  hl.dsp.exec_cmd("omarchy-hyprland-monitor-scaling-cycle --reverse"))

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
-- Laptop multimedia keys for volume and LCD brightness (with OSD)
o.bind("XF86AudioRaiseVolume", "Volume up", hl.dsp.exec_cmd("omarchy-swayosd-client --output-volume raise"),
  { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", hl.dsp.exec_cmd("omarchy-swayosd-client --output-volume lower"),
  { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", hl.dsp.exec_cmd("omarchy-swayosd-client --output-volume mute-toggle"),
  { locked = true, repeating = true })
o.bind("XF86AudioMicMute", "Mute microphone", hl.dsp.exec_cmd("omarchy-audio-input-mute"),
  { locked = true, repeating = true })
o.bind("XF86MonBrightnessUp", "Brightness up", hl.dsp.exec_cmd("omarchy-brightness-display +5%"),
  { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", hl.dsp.exec_cmd("omarchy-brightness-display 5%-"),
  { locked = true, repeating = true })
o.bind(modShift .. " + XF86MonBrightnessUp", "Brightness maximum", hl.dsp.exec_cmd("omarchy-brightness-display 100%"),
  { locked = true, repeating = true })
o.bind(modShift .. " + XF86MonBrightnessDown", "Brightness minimum", hl.dsp.exec_cmd("omarchy-brightness-display 1%"),
  { locked = true, repeating = true })
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", hl.dsp.exec_cmd("omarchy-brightness-keyboard up"),
  { locked = true, repeating = true })
o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", hl.dsp.exec_cmd("omarchy-brightness-keyboard down"),
  { locked = true, repeating = true })
o.bind("XF86KbdLightOnOff", "Keyboard backlight cycle", hl.dsp.exec_cmd("omarchy-brightness-keyboard cycle"),
  { locked = true })
o.bind("XF86TouchpadToggle", "Toggle touchpad", hl.dsp.exec_cmd("omarchy-toggle-touchpad"), { locked = true })
o.bind("XF86TouchpadOn", "Enable touchpad", hl.dsp.exec_cmd("omarchy-toggle-touchpad on"), { locked = true })
o.bind("XF86TouchpadOff", "Disable touchpad", hl.dsp.exec_cmd("omarchy-toggle-touchpad off"), { locked = true })

-- Precise 1% multimedia adjustments with Alt modifier
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", hl.dsp.exec_cmd("omarchy-swayosd-client --output-volume +1"),
  { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", hl.dsp.exec_cmd("omarchy-swayosd-client --output-volume -1"),
  { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", hl.dsp.exec_cmd("omarchy-brightness-display +1%"),
  { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", hl.dsp.exec_cmd("omarchy-brightness-display 1%-"),
  { locked = true, repeating = true })

-- Requires playerctl
o.bind("XF86AudioNext", "Next track", hl.dsp.exec_cmd("omarchy-swayosd-client --playerctl next"), { locked = true })
o.bind("XF86AudioPause", "Pause", hl.dsp.exec_cmd("omarchy-swayosd-client --playerctl play-pause"), { locked = true })
o.bind("XF86AudioPlay", "Play", hl.dsp.exec_cmd("omarchy-swayosd-client --playerctl play-pause"), { locked = true })
o.bind("XF86AudioPrev", "Previous track", hl.dsp.exec_cmd("omarchy-swayosd-client --playerctl previous"),
  { locked = true })

-- Switch audio output with Super + Mute
o.bind(mod .. " + XF86AudioMute", "Switch audio output", hl.dsp.exec_cmd("omarchy-audio-output-switch"),
  { locked = true })

-- ─── Notifications ─────────────────────
o.bind(mod .. " + COMMA", "Dismiss last notification", hl.dsp.exec_cmd("makoctl dismiss"))
o.bind(modShift .. " + COMMA", "Dismiss all notifications", hl.dsp.exec_cmd("makoctl dismiss --all"))
o.bind(modCtrl .. " + COMMA", "Toggle silencing notifications", hl.dsp.exec_cmd("omarchy-toggle-notification-silencing"))
o.bind(modAlt .. " + COMMA", "Invoke last notification", hl.dsp.exec_cmd("makoctl invoke"))
o.bind(modShiftAlt .. " + COMMA", "Restore last notification", hl.dsp.exec_cmd("makoctl restore"))

-- ─── Captures ─────────────────────
o.bind("PRINT", "Screenshot", hl.dsp.exec_cmd("omarchy-capture-screenshot"))
o.bind_menu("ALT + PRINT", "Screenrecording", "screenrecord")
o.bind(mod .. " + PRINT", "Color picker", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"))
o.bind(modCtrl .. " + PRINT", "Extract text (OCR) from screenshot", hl.dsp.exec_cmd("omarchy-capture-text-extraction"))

-- ─── Reminders ─────────────────────
o.bind_menu(modCtrl .. " + R", "Set reminder", "reminder-set")
o.bind(modCtrlAlt .. " + R", "Show reminders", hl.dsp.exec_cmd("omarchy-reminder show"))
o.bind(modShiftCtrl .. " + R", "Clear reminders", hl.dsp.exec_cmd("omarchy-reminder clear"))

-- ─── Others ─────────────────────
-- Waybar-less information
o.bind(modCtrlAlt .. " + T", "Show time", hl.dsp.exec_cmd("omarchy-notification-time"))
o.bind(modCtrlAlt .. " + B", "Show battery remaining", hl.dsp.exec_cmd("omarchy-notification-battery"))
o.bind(modCtrlAlt .. " + W", "Show weather", hl.dsp.exec_cmd("omarchy-notification-weather"))

-- Control panels
o.bind(mod .. " + A", "Audio controls", { omarchy = "audio" })
o.bind(mod .. " + B", "Bluetooth controls", { omarchy = "bluetooth" })
o.bind(mod .. " + W", "Wifi controls", { omarchy = "wifi" })

-- Zoom
o.bind(modCtrl .. " + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
o.bind(modCtrlAlt .. " + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Lock system
if o.file_exists(o.home .. "/.local/share/quickshell-lockscreen/lock.sh") then
  o.bind(modCtrl .. " + L", "Lock system", hl.dsp.exec_cmd("~/.local/share/quickshell-lockscreen/lock.sh"))
else
  o.bind(modCtrl .. " + L", "Lock system", hl.dsp.exec_cmd("omarchy-system-lock"))
end

-- Clipboard
o.bind(mod .. " + C", "Clipboard manager", { omarchy = "walker -m clipboard" }, { locked = true })
