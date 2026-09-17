if [[ -z "$WAYLAND_DISPLAY" && -z "$SSH_CONNECTION" && "$(tty)" == "/dev/tty1" ]]; then
  exec start-hyprland
fi
