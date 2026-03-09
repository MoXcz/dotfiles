#!/usr/bin/env bash

# To use this script first make sure that the frontmatter below is exactly what
# you want

set -e

add_frontmatter() {
  file="$1"

  if head -n1 "$file" | grep -q "^---"; then
    echo "Frontmatter already exists in $file"
    return
  fi

  tmp=$(mktemp)

  cat <<EOF >"$tmp"
---
tags:
  - journal
  - daily
---
EOF

  cat "$file" >>"$tmp"
  mv "$tmp" "$file"

  echo "Added frontmatter to $file"
}

remove_frontmatter() {
  file="$1"

  if ! head -n1 "$file" | grep -q "^---"; then
    echo "No frontmatter in $file"
    return
  fi

  tmp=$(mktemp)

  awk '
  NR==1 && $0=="---" {infront=1; next}
  infront && $0=="---" {infront=0; next}
  !infront {print}
  ' "$file" >"$tmp"

  mv "$tmp" "$file"

  echo "Removed frontmatter from $file"
}

process() {
  action="$1"
  path="$2"

  if [ -f "$path" ]; then
    "$action" "$path"
  elif [ -d "$path" ]; then
    for f in "$path"/*.md; do
      [ -e "$f" ] || continue
      "$action" "$f"
    done
  else
    echo "Invalid path"
  fi
}

case "$1" in
add)
  process add_frontmatter "$2"
  ;;
remove)
  process remove_frontmatter "$2"
  ;;
*)
  echo "Usage:"
  echo "  frontmatter.sh add <file|directory>"
  echo "  frontmatter.sh remove <file|directory>"
  ;;
esac
