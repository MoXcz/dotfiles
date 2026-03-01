#!/usr/bin/env bash

#languages=$(echo "c cpp python golang rust typescript" | tr " " "\n")
#core_utils=$(echo "find xargs sed awk" | tr " " "\n")
#selected=$(echo -e "$languages\n$core_utils" | fzf)

selected=$(cat ~/.config/tmux/.tmux-cht-languages ~/.config/tmux/.tmux-cht-command | fzf)
if [[ -z $selected ]]; then
    exit 0
fi

read -pr "Query: " query

if echo "$languages" | grep -qs "$selected"; then
  tmux split-window -p 32 -h bash -c "curl cht/.sh/$selected/$(echo "$query" | tr ' ' '+') | less -r"
else
  tmux split-window -p 32 -h bash -c "curl cht.sh/$selected~$query | less -r"
fi
