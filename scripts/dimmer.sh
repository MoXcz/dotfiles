#!/usr/bin/env bash

export DISPLAY=:0
# d1="eDP-1"
# d2="HDMI-A-1"
d1="XWAYLAND0"
d2="XWAYLAND1"

notif() {
  notify-send -t 3000 -h string:bgcolor:#ebcb8b "Brightness adjusted!"
}

[ "$1" = 10 ] && percent="1" || percent="0.$1"

[ "$2" = night ] && gamma="1.0:0.95:0.85" || gamma="1.0:1.0:1.0"

xorg() {
  xrandr --output "$d1" --brightness "$percent" --gamma "$gamma" && xrandr --output "$d2" --brightness "$percent" --gamma "$gamma" && notif
}

wayland() {
  gammastep -O 5500
}

wayland
