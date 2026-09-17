-- Shared helpers for Hyprland Lua configuration.

o = o or {}

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

o.shell_quote = shell_quote

-- Hyprland reaps its own children, so os.execute() can't retrieve an exit status
-- from inside the compositor. Read a marker off stdout instead.
local function command_from(value)
  if type(value) ~= "table" then
    return value
  end

  if value.launch then
    return o.launch(value.launch)
  elseif value.tui then
    return o.launch("kitty -e " .. value.tui)
  end

  return value
end

function o.bind(keys, description, dispatcher, options)
  local opts = options or {}

  if description then
    opts.description = description
  end

  dispatcher = command_from(dispatcher)

  if type(dispatcher) == "string" then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end

  hl.bind(keys, dispatcher, opts)
end

function o.launch(command)
  return command
end

function o.exec_on_start(command)
  hl.on("hyprland.start", function()
    hl.exec_cmd(command)
  end)
end

function o.launch_on_start(command)
  o.exec_on_start(o.launch(command))
end

function o.bind_menu(keys, description, menu, options)
  o.bind(keys, description, "menu " .. (menu or "launcher"), options)
end

function o.bind_toggle(keys, description, toggle, options)
  o.bind(keys, description, toggle, options)
end

function o.notify(message)
  return "notify-send -u low " .. shell_quote(message)
end

function o.window(match, rules)
  rules.match = rules.match or {}

  if type(match) == "string" then
    rules.match.class = match
  else
    for key, value in pairs(match) do
      rules.match[key] = value
    end
  end

  hl.window_rule(rules)
end

-- Require every *.lua file in a directory in sorted order.
-- Used for extension-style folders such as hypr/apps.
-- Pass a module prefix for normal package.path modules, e.g.
-- Pass nil as the prefix when the directory itself has been added to package.path.
function o.files(dir, module_prefix, options)
  local handle = io.popen("find -L " ..
    shell_quote(dir) .. " -maxdepth 1 -type f -name '*.lua' -printf '%f\\n' 2>/dev/null | sort")
  if handle then
    for filename in handle:lines() do
      local module = filename:gsub("%.lua$", "")
      if module_prefix then
        module = module_prefix .. "." .. module
      end

      if options and options.reload then
        package.loaded[module] = nil
      end

      require(module)
    end
    handle:close()
  end
end

function o.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

o.home = os.getenv("HOME")
o.config_home = os.getenv("XDG_CONFIG_HOME") or (o.home .. "/.config")
o.state_home = os.getenv("XDG_STATE_HOME") or (o.home .. "/.local/state")
