#!/usr/bin/env bash

# The dollar sign indicates that whatever is the output that is inside of it,
# it will be stored and then saved in session.
# session=$(find ~ ~/indv/ -mindepth 1 -maxdepth 1 -type d | fzf)

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/ ~/dev/ ~/indv/ -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . " ")
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"
