#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/ ~/Documents ~/workspace/ -mindepth 1 -maxdepth 2 -type d | sort | uniq | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . " ")
tmux_running=$(pgrep tmux)

switch_to() {
  if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux attach-session -t "$selected_name"
  else
    tmux switch-client -t "$selected_name"
  fi
}

if tmux has-session -t="$selected_name" 2> /dev/null; then
  switch_to
  exit 0
else
  tmux new-session -ds "$selected_name" -c "$selected"
  switch_to
fi
