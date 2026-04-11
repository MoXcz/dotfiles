#!/usr/bin/env bash

languages="c cpp python golang rust typescript"

selected=$(
  cat ~/.config/tmux/.tmux-cht-languages \
    ~/.config/tmux/.tmux-cht-command 2>/dev/null | fzf
)

[[ -z "$selected" ]] && exit 0

read -rp "Query: " query
[[ -z "$query" ]] && exit 0

encoded_query=$(printf '%s' "$query" | tr ' ' '+')

if echo "$languages" | tr ' ' '\n' | grep -qx "$selected"; then
  tmux split-window -p 32 -h \
    "curl -s \"https://cht.sh/$selected/$encoded_query\" | less -R"
else
  tmux split-window -p 32 -h \
    "curl -s \"https://cht.sh/$selected~$encoded_query\" | less -R"
fi
