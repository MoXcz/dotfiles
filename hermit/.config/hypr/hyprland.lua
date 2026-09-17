local home = os.getenv("HOME")
local reload_prefixes = {
  "hypr",
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

-- Load user modules from ~/.config.
package.path = home
    .. "/.local/state/?.lua;"
    .. "/.config/?.lua;"
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

-- Window decoration colors of the active theme (theme).
do
  local theme = o.state_home .. "/hermit/theme.lua"
  if o.file_exists(theme) then
    dofile(theme)
  end
end

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
