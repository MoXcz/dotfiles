#!/usr/bin/env bash

folder="/home/mocos/Notes/vi/"

newnote() { \
  name="$(echo "" | bemenu -c -sb "#a3be8c" -nf "#d8dee9" -p "Enter a name: ")"
  setsid tmux neww nvim "$folder$name.md" >/dev/null 2>&1
  # setsid -f "ghostty" -e nvim "$folder$name.md" >/dev/null 2>&1
}
# set('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer.sh<CR>')


selected() { \
  choice=$(echo -e "New\n$(ls -t1 $folder)" | bemenu -c -l 5 -i -p "Choose note or create new: ")
  case $choice in
    New) newnote ;;
    *md) tmux neww nvim "$folder$choice" >/dev/null 2>&1 ;;
    # *md) setsid -f "ghostty" -e nvim "$folder$choice" >/dev/null 2>&1 ;;
    *) exit ;;
  esac
}

selected

# From: https://www.youtube.com/watch?v=h_E3ddNQ1xw
