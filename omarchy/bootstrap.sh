#!/usr/bin/env bash

set -euo pipefail

read -rp "This will modify Omarchy default installation. Continue? [y/N] " confirm
[[ "$confirm" != "y" ]] && exit 0

echo "Starting system post-omarchy script..."

REPO_URL="https://github.com/MoXcz/dotfiles"
REPO_NAME="dotfiles"

echo "Checking dependencies..."

if ! command -v stow >/dev/null; then
    echo "stow not found. Install it first:"
    echo "  sudo pacman -S stow"
    exit 1
fi

if ! command -v yay >/dev/null; then
    echo "yay not found. Install it first."
    exit 1
fi

cd "$HOME"

if [[ -d "$REPO_NAME" ]]; then
    echo "Repository '$REPO_NAME' already exists. Skipping clone."
else
    echo "Cloning dotfiles..."
    git clone "$REPO_URL" "$REPO_NAME"
fi

echo "Removing conflicting configs..."

rm -rf ~/.config/{nvim,hypr,alacritty,ghostty,waybar,kitty}
rm -rf ~/.local/share/nvim ~/.cache/nvim
rm -f ~/.config/starship.toml

echo "Deploying dotfiles with stow..."

cd "$REPO_NAME"
./setup.sh omarchy

echo "Installing packages..."

yay -S --needed \
  zsh \
  zen-browser \
  syncthing \
  tmux \
  protonplus \
  ghostty \
  vulkan-radeon \
  vulkan-tools \
  ttf-iosevka-term \
  ttf-iosevkaterm-nerd \
  sioyek

echo "Change shell to zsh"

chsh -s "$(which zsh)"

echo "Setup complete."
