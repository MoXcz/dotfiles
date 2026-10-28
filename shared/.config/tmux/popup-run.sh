#!/usr/bin/env bash
# usage: popup-run.sh <name> <dir> <current-session> <client> <command...>
name="$1"
dir="$2"
current="$3"
client="$4"
shift 4
cmd="$*"

hash=$(echo -n "$dir" | md5sum | cut -c1-8)
# tmux rewrites '.' and ':' in session names, which breaks has-session lookups
base=$(basename "$dir"); base="${base//[^[:alnum:]_-]/_}"
session="${name}-${base}-${hash}"

[[ $current == "$name"-* ]] && {
  tmux detach-client -t "$client"
  exit
}

if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -c "$dir" "$cmd"
  tmux set -t "$session" detach-on-destroy on
  # tagged so prefix s/S can tell agent popups from work sessions
  tmux set -t "$session" @popup agent
fi

tmux display-popup -c "$client" -w 80% -h 80% -E "tmux attach-session -t $session"
