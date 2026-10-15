#!/usr/bin/env bash
# usage: worktree.sh add|open|close|remove <client>
action="$1"
client="$2"

fail() {
  echo "$1"
  read -rn 1 -s
  exit 1
}

common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || fail "Not a git repository"
root=$(dirname "$common_dir")
base="$(dirname "$root")/$(basename "$root").worktrees"
session=$(tmux display -p -c "$client" '#{session_name}')

list_worktrees() {
  git -C "$root" worktree list --porcelain | awk -v root="$root" '
    /^worktree / { path = substr($0, 10) }
    /^branch /   { if (path != root) print substr($0, 19) "\t" path }'
}

pick_worktree() {
  list_worktrees | fzf --prompt="$1 > " --delimiter='\t' --with-nth=1
}

# Windows are tagged with their worktree path so they can be found again after a rename.
find_window() {
  tmux list-windows -a -F '#{window_id} #{@worktree}' |
    awk -v path="$1" 'substr($0, index($0, " ") + 1) == path { print $1; exit }'
}

open_window() {
  local branch=$1 path=$2 win
  win=$(find_window "$path")
  if [ -z "$win" ]; then
    win=$(tmux new-window -d -P -F '#{window_id}' -t "$session:" -n "$branch" -c "$path")
    tmux set -w -t "$win" @worktree "$path"
  fi
  tmux switch-client -c "$client" -t "$win"
}

case "$action" in
add)
  branch=$(git -C "$root" branch -a --format='%(refname:short)' | sed 's#^origin/##' | grep -v '^HEAD$' | sort -u |
    fzf --prompt="branch (type a new name to create) > " --print-query | tail -n 1)
  [ -z "$branch" ] && exit 0
  path="$base/$branch"
  if git -C "$root" rev-parse -q --verify "refs/heads/$branch" >/dev/null ||
    git -C "$root" rev-parse -q --verify "refs/remotes/origin/$branch" >/dev/null; then
    git -C "$root" worktree add "$path" "$branch" || fail "worktree add failed"
  else
    git -C "$root" worktree add -b "$branch" "$path" || fail "worktree add failed"
  fi
  open_window "$branch" "$path"
  ;;
open)
  selection=$(pick_worktree open) || exit 0
  open_window "${selection%%$'\t'*}" "${selection#*$'\t'}"
  ;;
close | remove)
  selection=$(pick_worktree "$action") || exit 0
  branch="${selection%%$'\t'*}"
  path="${selection#*$'\t'}"
  win=$(find_window "$path")
  [ -n "$win" ] && tmux kill-window -t "$win"
  [ "$action" = close ] && exit 0
  git -C "$root" worktree remove "$path" || fail "worktree has changes; commit or stash first"
  git -C "$root" branch -d "$branch" || fail "branch not merged; kept it (git branch -D $branch to force)"
  ;;
esac
