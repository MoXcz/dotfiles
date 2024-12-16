local wezterm = require("wezterm")
local sessionizer = require("sessionizer")
local act = wezterm.action
require "status"

local config = wezterm.config_builder()

config = {
	leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 },
	keys = {
		{ mods = "LEADER", key = "l", action = wezterm.action.ShowLauncher },
		{ mods = "LEADER", key = "f", action = wezterm.action_callback(sessionizer.toggle) },
		{ mods = "LEADER", key = "c", action = act.SpawnTab("CurrentPaneDomain") },
		{ mods = "LEADER", key = "x", action = act.CloseCurrentPane({ confirm = true }) },
		{ mods = "LEADER", key = "p", action = act.ActivateTabRelative(-1) },
		{ mods = "LEADER", key = "n", action = act.ActivateTabRelative(1) },
		{ mods = "LEADER", key = "'", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ mods = "LEADER", key = "-", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ mods = "LEADER", key = "h", action = act.ActivatePaneDirection("Left") },
		{ mods = "LEADER", key = "j", action = act.ActivatePaneDirection("Down") },
		{ mods = "LEADER", key = "k", action = act.ActivatePaneDirection("Up") },
		{ mods = "LEADER", key = "l", action = act.ActivatePaneDirection("Right") },
	},

}

for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

return config
