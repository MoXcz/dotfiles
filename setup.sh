#!/usr/bin/env bash

set -euo pipefail

PROFILE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TARGET_DIR="$HOME"
SHARED_DIR="shared"

if ! command -v stow >/dev/null 2>&1; then
  echo "Error: stow is not installed."
  exit 1
fi

if [[ ! -d "$SHARED_DIR" ]]; then
  echo "Error: Shared directory '$SHARED_DIR' not found."
  exit 1
fi

PROFILES=("omarchy" "paradise-lost")

unstow_others() {
  local selected="$1"

  for p in "${PROFILES[@]}"; do
    if [[ "$p" != "$selected" ]] && [[ -d "$p" ]]; then
      echo "Unstowing $p..."
      stow -D -v -t "$TARGET_DIR" "$p" || true
    fi
  done
}

stow_shared() {
  echo "Stowing shared config (.config)..."
  stow -v -t "$TARGET_DIR" "$SHARED_DIR"
}

stow_profile() {
  local profile="$1"

  if [[ ! -d "$profile" ]]; then
    echo "Directory '$profile' not found."
    exit 1
  fi

  echo -e "\nSwitching to profile: $profile\n"

  unstow_others "$profile"
  stow_shared

  echo "Stowing $profile..."
  stow -v -t "$TARGET_DIR" "$profile"
  # setup_nvim

  echo -e "\nDone."
}

setup_nvim() {
  NVIM_REPO="https://github.com/MoXcz/nvim"
  NVIM_DIR="$HOME/.config/nvim"
  echo "Setting up Neovim config..."

  if [[ -d "$NVIM_DIR/.git" ]]; then
    echo "Neovim config already exists. Updating..."
    git -C "$NVIM_DIR" pull
  else
    echo "Cloning Neovim config..."
    git clone "$NVIM_REPO" "$NVIM_DIR"
  fi
}

options=("omarchy" "paradise-lost" "Quit")

if [[ -n "$PROFILE" ]]; then
  stow_profile "$PROFILE"
  exit 0
fi

PS3=$'\nSelect a profile to stow: '

select opt in "${options[@]}"; do
  [[ "$opt" == "Quit" ]] && exit

  if [[ -n "$opt" ]]; then
    stow_profile "$opt"
    break
  else
    echo "Invalid selection."
  fi
done
