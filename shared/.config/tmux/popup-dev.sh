#!/usr/bin/env bash

dir="$1"
hash=$(echo -n "$dir" | md5sum | cut -c1-8)
session="dev-${hash}"

if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -c "$dir"
  tmux split-window -h -t "$session" -c "$dir/web-platform"

  # get actual pane IDs regardless of base-index
  panes=($(tmux list-panes -t "$session" -F '#{pane_id}'))
  left="${panes[0]}"
  right="${panes[1]}"

  tmux send-keys -t "$left" "go run ./cmd/web -dev" C-m
  tmux send-keys -t "$right" "npm run dev" C-m
fi

tmux display-popup -w 90% -h 85% -E "tmux attach-session -t $session"
