-- Control your input devices.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

local function read_vconsole()
  local values = {}
  local file = io.open("/etc/vconsole.conf", "r")
  if not file then
    return values
  end

  for line in file:lines() do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key and value then
      value = value:gsub("%s+#.*$", "")
      value = value:gsub('^"(.*)"$', "%1")
      value = value:gsub("^'(.*)'$", "%1")
      values[key] = value
    end
  end

  file:close()
  return values
end

-- Layouts that cannot type Latin letters need a leading US layout so bindings
-- continue to work.
local non_latin_layouts =
" af am ara bd bg by et ge gr il in iq ir kg kh kz la lk mk mm mn mv np rs ru sy th tj ua "

local vconsole = read_vconsole()

-- Layouts available in the session, in order. The first one is what
-- keybindings resolve against, so a Latin layout has to lead.
--
-- The list is state rather than config: `keyboard add|remove` writes
-- it, the Keyboard route in the menu switches between the entries, and Left
-- Alt + Space cycles them. /etc/vconsole.conf only wins when it names more
-- than one layout itself, since a single console keymap cannot express a
-- session list (and is "us" on most installs).
local function read_layouts()
  local file = io.open(o.state_home .. "/shell/keyboard-layouts", "r")
  if not file then
    return nil
  end

  local line = file:read("l")
  file:close()

  line = (line or ""):gsub("%s+", "")
  return line ~= "" and line or nil
end

local vconsole_layout = vconsole.XKBLAYOUT or ""
local kb_layout = read_layouts()
  or (vconsole_layout:find(",", 1, true) and vconsole_layout)
  or "us,latam"
local kb_variant = vconsole.XKBVARIANT or ""
local kb_options = "caps:escape"

if kb_layout:find(",", 1, true) then
  kb_options = kb_options .. ",grp:alt_space_toggle"
end

-- Hyprland resolves keybindings against the first entry in kb_layout, not the
-- layout that's currently active, so Latin-keysym bindings only fire when a
-- Latin layout leads. Installing with a non-Latin
-- one would otherwise leave the desktop unusable.
if non_latin_layouts:find(" " .. kb_layout:match("^[^,]*") .. " ", 1, true) then
  kb_layout = "us," .. kb_layout
  kb_variant = "," .. kb_variant
  -- Reach the original layout with Left Alt + Right Alt.
  kb_options = kb_options .. ",grp:alts_toggle"
end

hl.config({
  input = {
    -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
    kb_layout = kb_layout,

    -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
    kb_variant = kb_variant,
    kb_model = "",
    kb_options = kb_options, -- ,grp:alts_toggle
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,

    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 250,

    -- Start with numlock on by default.
    numlock_by_default = true,

    -- Turn off mouse acceleration (default: adaptive).
    accel_profile = "flat",

    touchpad = {
      -- inverse scrolling
      natural_scroll = false,

      -- Use two-finger clicks for right-click instead of lower-right corner.
      clickfinger_behavior = true,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,

      -- Enable the touchpad while typing.
      -- disable_while_typing = false,

      -- Left-click-and-drag with three fingers.
      -- drag_3fg = 1,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })
