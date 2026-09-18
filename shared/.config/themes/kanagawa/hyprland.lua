-- Window decoration colors for the kanagawa theme. Copied into the state
-- directory by theme and loaded from hyprland.lua.
local active_border_color = "rgb(dcd7ba)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = "rgb(363646)",
    },
  },

  group = {
    col = {
      border_active = active_border_color,
    },
  },
})
