#!/usr/bin/env bash

CARD="Master"

status=$(amixer get "$CARD")
mute="no"
volume=$(echo "$status" | grep -oP '\[\d+%\]' | head -n1 | tr -d '[]%')

if echo "$status" | grep -q "\[off\]"; then
  mute="yes"
fi


if [ "$mute" = "yes" ]; then
    icon=" "
elif [ "$volume" -lt 50 ]; then
    icon=" "
else
    icon=" "
fi

echo "$icon $volume%"

case "$BLOCK_BUTTON" in
    1) xdg-terminal-exec wiremix ;;
    3) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
esac
