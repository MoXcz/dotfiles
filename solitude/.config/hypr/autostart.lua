hl.on("hyprland.start", function()
  -- Slow app launch fix -- set systemd vars before starting session services.
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  hl.exec_cmd("systemctl --user start hypridle.service")
  hl.exec_cmd("launch-shell")
  -- Pauses hyprmoncfg while an unconfigured monitor is plugged in, so it is
  -- not switched off before you can arrange it.
  hl.exec_cmd("systemd-cat -t monitor-guard monitor-guard")
  hl.exec_cmd("background restore")
  hl.exec_cmd("gtk-theme")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)
