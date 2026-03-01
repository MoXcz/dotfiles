#!/usr/bin/env bash

DIR=$(pwd)
REPO_URL="https://github.com/MoXcz/dotfiles-omarchy"
REPO_NAME="dotfiles"

if ! pacman -Qi "stow" &> /dev/null; then
  echo -e "Install stow:\n  pacman -S stow"
  exit 1
fi

cd $HOME

if [ -d "$REPO_NAME" ]; then
  echo "Repository '$REPO_NAME' already exists. Skipping clone"
else
  git clone "$REPO_URL" "$REPO_NAME"
fi

if [ $? -eq 0 ]; then
  echo "Removing omarchy dotfiles 'config' files..."
  rm -rf ~/.config/nvim \
    ~/.config/starship.toml \
    ~/.local/share/nvim/ \
    ~/.local/share/nvim/ \
    ~/.cache/nvim/ \
    ~/.config/hypr/ \
    ~/.config/alacritty \
    ~/.config/ghostty \
    ~/.config/waybar \
    ~/.config/kitty

  cd "$REPO_NAME"
  stow .
else
  echo "Failed to clone repository"
  exit 1
fi

echo "Installing packages..."

yay -S \
  zsh zen-browser syncthing \
  tmux syncthing protonplus ghostty \
  vulkan-radeon vulkan-tools \
  ttf-iosevka-term ttf-iosevkaterm-nerd
