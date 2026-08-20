local home = os.getenv("HOME")
local reload_prefixes = {
  "default.hypr",
  "hypr",
  "omarchy.current.theme",
}

local function should_reload_module(module)
  for _, prefix in ipairs(reload_prefixes) do
    if module == prefix or module:sub(1, #prefix + 1) == prefix .. "." then
      return true
    end
  end

  return false
end

local modules_to_reload = {}
for module in pairs(package.loaded) do
  if should_reload_module(module) then
    table.insert(modules_to_reload, module)
  end
end

for _, module in ipairs(modules_to_reload) do
  package.loaded[module] = nil
end

-- Load generated state from ~/.local/state, user modules from ~/.config, and
-- Omarchy defaults from $OMARCHY_PATH.
package.path = home
    .. "/.local/state/?.lua;"
    .. "/.config/?.lua;"
    .. (os.getenv("OMARCHY_PATH") or "/usr/share/omarchy")
    .. "/?.lua;"
    .. package.path

package.path = package.path .. ";" .. os.getenv("HOME")
    .. "/.config/?.lua;"

require("hypr.helpers")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.envs")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.windows")
require("hypr.apps")


function module(module)
  if package.searchpath(module, package.path) then
    return require(module)
  end
end

module("omarchy.current.theme.hyprland")

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
dofile((os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/hyprmoncfg-monitors.lua")
