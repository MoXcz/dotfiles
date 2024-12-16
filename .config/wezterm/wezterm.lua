-- Pull in the wezterm API
local wezterm = require('wezterm')

-- In newer versions of wezterm, use the config_builder which will help provide clearer error messages
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
config = {
  automatically_reload_config = true,

  enable_tab_bar = false,
  window_decorations = 'RESIZE',
  color_scheme = 'Everblush (Gogh)',
  -- color_scheme = "Everforest Dark (Gogh)",
  -- Change value depending on the background color
  window_background_opacity = 0.9,

  font = wezterm.font('JetBrainsMono Nerd Font'),
  font_size = 16,
}

-- and finally, return the configuration to wezterm
return config
