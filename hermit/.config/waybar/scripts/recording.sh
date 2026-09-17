#!/usr/bin/env bash
# Red dot while `screenrecord` is running.

PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/screenrecord.pid"

if [[ -f $PID_FILE ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo '{"text": "󰑊", "tooltip": "Recording · click to stop", "class": "active"}'
else
  echo '{"text": "", "class": "idle"}'
fi
