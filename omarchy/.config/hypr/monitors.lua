local gdk_scale = 1
local monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(gdk_scale))

-- List current monitors and resolutions possible: hyprctl monitors all
hl.monitor({ output = "DP-1", mode = "2560x1440@180", position = "auto", scale = monitor_scale })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@120", position = "auto", scale = monitor_scale })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°)
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- Example for Framework 13 w/ 6K XDR Apple display.
-- hl.monitor({ output = "DP-5", mode = "6016x3384@60", position = "auto", scale = 2 })
-- hl.monitor({ output = "eDP-1", mode = "2880x1920@120", position = "auto", scale = 2 })

-- Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
-- local omarchy_gdk_scale = 2
-- local omarchy_monitor_scale = "auto"

-- Good compromise for 27" or 32" 4K monitors (but fractional!): monitor scale 1.6, GDK scale 1.75.
-- local omarchy_gdk_scale = 1.75
-- local omarchy_monitor_scale = 1.6

-- Straight 1x setup for low-resolution displays like 1080p, 1440p, or ultrawides: both 1.
-- local omarchy_gdk_scale = 1
-- local omarchy_monitor_scale = 1
