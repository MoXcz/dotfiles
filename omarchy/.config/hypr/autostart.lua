hl.on("hyprland.start", function()
  -- Slow app launch fix -- set systemd vars before starting session services.
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  hl.exec_cmd("omarchy-launch-shell")
  hl.exec_cmd("omarchy-provision-first-run")
  hl.exec_cmd("omarchy-powerprofiles-init")
  hl.exec_cmd(o.launch("omarchy-hyprland-monitor-watch"))
  hl.exec_cmd(o.launch("udiskie --automount --no-notify --no-tray"))

  -- Run post-boot hooks after startup config has loaded.
  hl.exec_cmd("sleep 2 && omarchy-hook post-boot")
end)

-- o.launch_on_start("hypridle")
-- o.launch_on_start("mako")
-- o.exec_on_start("! omarchy-toggle-enabled waybar-off && " .. o.launch("waybar"))
-- o.launch_on_start("fcitx5 --disable notificationitem")
-- o.launch_on_start("swaybg -i ~/.config/omarchy/current/background -m fill")
-- o.exec_on_start("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
-- o.exec_on_start("omarchy-first-run")
-- o.exec_on_start("omarchy-powerprofiles-init")
-- o.launch_on_start("omarchy-hyprland-monitor-watch")
--
-- -- Slow app launch fix -- set systemd vars.
-- o.exec_on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")
-- o.exec_on_start("dbus-update-activation-environment --systemd --all")
--
-- -- Run post-boot hooks after startup config has loaded.
-- o.exec_on_start("sleep 2 && omarchy-hook post-boot")
