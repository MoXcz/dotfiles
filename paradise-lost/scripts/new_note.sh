#!/usr/bin/env bash

folder="/home/mocos/Notes/vi"

newnote() {
  name="$(bemenu -c -sb "#a3be8c" -nf "#d8dee9" -p "Enter a name: ")"
  [[ -z "$name" ]] && exit 0

  tmux new-window "nvim \"$folder/$name.md\"" >/dev/null 2>&1
}

selected() {
  choice="$(
    {
      echo "New"
      find "$folder" -maxdepth 1 -type f -name "*.md" -printf "%f\n" | sort -r
    } | bemenu -c -l 5 -i -p "Choose note or create new: "
  )"

  [[ -z "$choice" ]] && exit 0

  case "$choice" in
    New)
      newnote
      ;;
    *.md)
      tmux new-window "nvim \"$folder/$choice\"" >/dev/null 2>&1
      ;;
    *)
      exit 0
      ;;
  esac
}

selected

# From: https://www.youtube.com/watch?v=h_E3ddNQ1xw
