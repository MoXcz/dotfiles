#!/usr/bin/env bash

set -e

# Lock the screen using swaylock with a custom wallpaper
swayidle -w \
  timeout 160 ' swaylock -f' \
  before-sleep 'swaylock -f'
