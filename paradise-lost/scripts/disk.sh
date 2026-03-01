#!/usr/bin/env bash

check_disk() {
  disk=$(df -h /home | awk '/^\/dev/ {print $5}' | sed 's/%//')

  if [ "$disk" -gt 80 ]; then
    echo "Disk is nearly full"
  else
    echo "There's still enough disk space"
  fi
}

case "$1" in
  disk) check_disk
  ;;
  mem) free -h | awk '/^Mem/ {print $3}'
  ;;
  *) echo "Pick disk or mem" && exit 0
  ;;
esac

