#!/bin/sh

LOCK_SCREEN=~/.config/backgrounds/signalis_wallpaper_2.png

lock() {
  if [ -e $LOCK_SCREEN ]
  then
    swaylock -i $LOCK_SCREEN
  else
    swaylock -c '#282A36'
  fi
}

lock

exit 0

