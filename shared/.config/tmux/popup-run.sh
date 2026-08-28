#!/usr/bin/env bash
# usage: popup-run.sh <name> <dir> <command...>
name="$1"
dir="$2"
shift 2
cmd="$*"

hash=$(echo -n "$dir" | md5sum | cut -c1-8)
session="${name}-${hash}"

if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -c "$dir" "$cmd"
fi

tmux display-popup -w 80% -h 80% -E "tmux attach-session -t $session"
