#!/usr/bin/env bash

cmd="$1"
[ -z "$cmd" ] && exit 1

selection=$(workmux list | tail -n +2 | fzf --prompt="Select a workmux session to $cmd: " --height=40% --border --ansi)
[ -z "$selection" ] && exit 0

branch=$(echo "$selection" | awk '{print $1}')
workmux "$cmd" "$branch" || { echo; echo "workmux $cmd failed"; read -n 1 -s; }
