#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/MoXcz/dotfiles"
REPO_NAME="dotfiles"
REPO_DIR="${DOTFILES_DIR:-$HOME/$REPO_NAME}"

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this script as your normal user, not root."
  exit 1
fi

sudo pacman -Syu --needed \
  base-devel git stow kitty rofi \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  wl-clipboard wl-clip-persist cliphist \
  grim slurp wf-recorder \
  polkit-gnome xdg-user-dirs

if ! command -v yay >/dev/null 2>&1; then
  yay_dir="$(mktemp -d)"
  trap 'rm -rf "$yay_dir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$yay_dir/yay"
  (cd "$yay_dir/yay" && makepkg -si --noconfirm)
  trap - EXIT
fi

yay -S --needed --noconfirm mangowm-git mangobar-git

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
./setup.sh mango

xdg-user-dirs-update

echo "MangoWM setup complete. Log out and select Mango from your session menu."
