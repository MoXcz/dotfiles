hl.on("hyprland.start", function()
  -- Slow app launch fix -- set systemd vars before starting session services.
  -- One chained command: exec_cmd runs asynchronously, so hypridle must not
  -- start until the environment import has finished. Otherwise hypridle can
  -- come up without HYPRLAND_INSTANCE_SIGNATURE and its hyprctl calls fail.
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)"
    .. " && dbus-update-activation-environment --systemd --all"
    .. " && systemctl --user start hypridle.service")

  -- Desktop shell: bar, notifications, OSD, clipboard history. The theme
  -- files waybar and mako include are rendered first, in the same command,
  -- so neither can start before they exist.
  hl.exec_cmd("theme apply && systemd-cat -t waybar waybar")
  hl.exec_cmd("theme apply && systemd-cat -t mako mako")
  hl.exec_cmd("systemd-cat -t swayosd swayosd-server")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  hl.exec_cmd("background restore")
  hl.exec_cmd("gtk-theme")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  -- Removable drives: mount on plug, tray icon.
  hl.exec_cmd("udiskie --appindicator")
end)
