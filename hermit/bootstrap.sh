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
  base-devel git stow hyprland hypridle hyprlock hyprsunset kitty nemo \
  waybar mako rofi swayosd cliphist wtype libnotify socat \
  pipewire pipewire-pulse wireplumber wiremix \
  networkmanager bluez bluez-utils bluetui udiskie btop \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprland-guiutils \
  polkit-gnome xdg-user-dirs \
  playerctl pamixer brightnessctl grim slurp wl-clipboard \
  hyprpicker satty tesseract tesseract-data-eng wf-recorder \
  ffmpeg imagemagick zenity gnome-calculator \
  ttf-iosevka-nerd noto-fonts-emoji swaybg \
  gnome-themes-extra adwaita-icon-theme adwaita-fonts \
  noto-fonts noto-fonts-cjk ttf-liberation \
  steam zsh tmux starship fzf unzip nodejs tree-sitter-cli npm rustup

if ! command -v yay >/dev/null 2>&1; then
  yay_dir="$(mktemp -d)"
  trap 'rm -rf "$yay_dir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$yay_dir/yay"
  (cd "$yay_dir/yay" && makepkg -si --noconfirm)
  trap - EXIT
fi

yay -S --needed --noconfirm \
  ttf-iosevka-term ttf-iosevkaterm-nerd \
  localsend-bin \
  zen-browser-bin

install_nvidia="${HERMIT_NVIDIA:-}"
if [[ -z "$install_nvidia" ]]; then
  if lspci 2>/dev/null | grep -qi 'nvidia'; then
    nvidia_default="Y/n"
  else
    nvidia_default="y/N"
  fi
  if [[ -r /dev/tty ]]; then
    read -r -p "Install NVIDIA drivers? [$nvidia_default] " install_nvidia </dev/tty || install_nvidia=""
  fi
  if [[ -z "$install_nvidia" ]]; then
    [[ "$nvidia_default" == "Y/n" ]] && install_nvidia="y" || install_nvidia="n"
  fi
fi

if [[ "${install_nvidia,,}" == y* ]]; then
  nvidia_packages=(nvidia-utils)
  if pacman -Qq linux >/dev/null 2>&1; then
    nvidia_packages+=(nvidia)
  fi
  if pacman -Qq linux-lts >/dev/null 2>&1; then
    nvidia_packages+=(nvidia-lts)
  fi
  if ((${#nvidia_packages[@]} == 1)); then
    echo "Hermit supports the linux and linux-lts kernels for NVIDIA." >&2
    exit 1
  fi
  sudo pacman -S --needed "${nvidia_packages[@]}"
else
  echo "Skipping NVIDIA drivers."
fi

autologin="${HERMIT_AUTOLOGIN:-}"
if [[ -z "$autologin" && -r /dev/tty ]]; then
  read -r -p "Log in automatically on tty1 and start Hyprland? [y/N] " autologin </dev/tty || autologin=""
fi
if [[ "${autologin,,}" == y* ]]; then
  sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
  sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null <<EOF_UNIT
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF_UNIT
  sudo systemctl daemon-reload
else
  echo "Skipping autologin; Hyprland still starts after a manual tty1 login."
fi

sudo systemctl enable --now NetworkManager bluetooth
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
for path in .config/hypr .config/waybar .config/mako .config/kitty .local/bin; do
  if [[ -e "$HOME/$path" && ! -L "$HOME/$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    mv "$HOME/$path" "$BACKUP_DIR/$path"
  fi
done

./setup.sh hermit

if command -v zsh >/dev/null 2>&1 && [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)"
fi

# Render the theme files waybar, mako, rofi and hyprlock include on first run
PATH="$HOME/.local/bin:$PATH" theme apply

echo "Setup complete. Previous configuration was backed up to $BACKUP_DIR."
echo "Select the Hyprland session from your display manager, or run: start-hyprland"
