#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/MoXcz/dotfiles"
REPO_NAME="dotfiles"
REPO_DIR="${DOTFILES_DIR:-$HOME/$REPO_NAME}"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this script as your normal user, not root."
  exit 1
fi

if ! pacman-conf --repo-list | grep -qx "multilib"; then
  # Steam is packaged in multilib, which is disabled in a stock pacman.conf.
  sudo sed -i -E '/^#\[multilib\]$/ { s/^#//; n; s/^#//; }' /etc/pacman.conf
fi

sudo pacman -Syu --needed \
  base-devel git stow hyprland hyprlock hypridle kitty nemo \
  waybar \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal-hyprland polkit-gnome networkmanager xdg-user-dirs \
  playerctl pamixer brightnessctl grim slurp \
  steam zsh

if ! command -v yay >/dev/null 2>&1; then
  yay_dir="$(mktemp -d)"
  trap 'rm -rf "$yay_dir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$yay_dir/yay"
  (cd "$yay_dir/yay" && makepkg -si --noconfirm)
  trap - EXIT
fi

yay -S --needed --noconfirm \
  walker elephant \
  ttf-iosevka-term ttf-iosevkaterm-nerd

nvidia_packages=(nvidia-utils)
if pacman -Qq linux >/dev/null 2>&1; then
  nvidia_packages+=(nvidia)
fi
if pacman -Qq linux-lts >/dev/null 2>&1; then
  nvidia_packages+=(nvidia-lts)
fi
if (( ${#nvidia_packages[@]} == 1 )); then
  echo "Solitude supports the linux and linux-lts kernels for NVIDIA." >&2
  exit 1
fi
sudo pacman -S --needed "${nvidia_packages[@]}"

sudo systemctl enable --now NetworkManager
systemctl --user enable --now pipewire pipewire-pulse wireplumber

if [[ -z "${DOTFILES_DIR:-}" ]]; then
  if [[ -d "$REPO_DIR/.git" ]]; then
    git -C "$REPO_DIR" pull --ff-only
  else
    git clone "$REPO_URL" "$REPO_DIR"
  fi
elif [[ ! -d "$REPO_DIR" ]]; then
  echo "DOTFILES_DIR does not exist: $REPO_DIR" >&2
  exit 1
fi

cd "$REPO_DIR"

xdg-user-dirs-update
mkdir -p "$HOME/Pictures"

mkdir -p "$BACKUP_DIR"
for path in .config/hypr .config/waybar .config/walker .config/kitty .config/alacritty; do
  if [[ -e "$HOME/$path" && ! -L "$HOME/$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    mv "$HOME/$path" "$BACKUP_DIR/$path"
  fi
done

./setup.sh solitude

if command -v zsh >/dev/null 2>&1 && [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)"
fi

echo "Setup complete. Previous configuration was backed up to $BACKUP_DIR."
echo "Select the Hyprland session from your display manager, or run: Hyprland"
