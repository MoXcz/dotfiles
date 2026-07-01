-- Load user modules from ~/.config
package.path = package.path .. ";" .. os.getenv("HOME")
    .. "/.config/?.lua;"

require("hypr.helpers")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.envs")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.apps")
require("hypr.windows")

-- require("default.hypr.toggles")
