local mod = "SUPER"
local shift = mod .. " + SHIFT"
local ctrl = mod .. " + CTRL"

local function bind(keys, description, command, options)
  o.bind(keys, description, hl.dsp.exec_cmd(command), options)
end

bind(mod .. " + RETURN", "Terminal", "kitty")
bind(mod .. " + N", "File manager", "nemo")
bind(mod .. " + D", "Launch apps", "walker")
bind(mod .. " + C", "Clipboard history", "walker -m clipboard")
bind(mod .. " + E", "Symbols", "walker -m symbols")
bind(mod .. " + K", "Keybindings", "walker -m keybindings")
bind(mod .. " + Q", "Close window", "hyprctl dispatch killactive")
bind(mod .. " + F", "Fullscreen", "hyprctl dispatch fullscreen 0")
bind(mod .. " + SPACE", "Toggle floating", "hyprctl dispatch togglefloating")
bind(ctrl .. " + L", "Lock system", "pidof hyprlock || hyprlock")

o.bind(mod .. " + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind(mod .. " + L", "Focus right", hl.dsp.focus({ direction = "r" }))
o.bind(mod .. " + UP", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind(mod .. " + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind(shift .. " + H", "Move left", hl.dsp.window.swap({ direction = "l" }))
o.bind(shift .. " + L", "Move right", hl.dsp.window.swap({ direction = "r" }))
o.bind(shift .. " + UP", "Move up", hl.dsp.window.swap({ direction = "u" }))
o.bind(shift .. " + J", "Move down", hl.dsp.window.swap({ direction = "d" }))

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind(mod .. " + " .. key, "Workspace " .. workspace,
    hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind(shift .. " + " .. key, "Move to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) }))
end

bind("XF86AudioRaiseVolume", "Volume up", "pamixer -i 5", { locked = true, repeating = true })
bind("XF86AudioLowerVolume", "Volume down", "pamixer -d 5", { locked = true, repeating = true })
bind("XF86AudioMute", "Mute", "pamixer -t", { locked = true })
bind("XF86MonBrightnessUp", "Brightness up", "brightnessctl set 5%+", { locked = true })
bind("XF86MonBrightnessDown", "Brightness down", "brightnessctl set 5%-", { locked = true })
bind("XF86AudioNext", "Next track", "playerctl next", { locked = true })
bind("XF86AudioPrev", "Previous track", "playerctl previous", { locked = true })
bind("XF86AudioPlay", "Play/pause", "playerctl play-pause", { locked = true })
bind("PRINT", "Screenshot", "grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%s).png")
bind(shift .. " + S", "Screenshot", "grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%s).png")
