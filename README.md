# My Dotfiles

Personal configuration files for Linux desktop environments, managed with [GNU Stow](https://www.gnu.org/software/stow/).

| Profile                               | Base OS    | WM                    |
| ------------------------------------- | ---------- | --------------------- |
| [**Omarchy**](./omarchy/)             | Arch Linux | Hyprland              |
| [**Solitude**](./solitude/)           | Arch Linux | Hyprland + Quickshell |
| [**Hermit**](./hermit/)               | Arch Linux | Hyprland + Waybar     |
| [**Paradise Lost**](./paradise-lost/) | Debian 12  | Sway / i3             |

- **Shell**: [Zsh](https://www.zsh.org/)
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/) with [tmux](https://github.com/tmux/tmux)
- **Editor**: [Neovim](https://neovim.io/)
- **Font**: [Iosevka Term](https://typeof.net/Iosevka/)
- **Colorscheme**: [Kanagawa](https://github.com/rebelot/kanagawa.nvim) and ashen.nvim
- **Bar**: [Waybar](https://github.com/Alexays/Waybar) and Quickshell

## Installation

### Prerequisites

- [Git](https://git-scm.com/)
- [GNU Stow](https://www.gnu.org/software/stow/)

```bash
sudo apt install git stow   # Debian/Ubuntu
sudo pacman -S git stow     # Arch
```

### Quick Start

Clone the repository inside `$HOME` and run the interactive setup:

```bash
git clone https://github.com/MoXcz/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
```

A menu will appear to select the profile you want to deploy. The script will:

1. Unstow any previously active profile
2. Stow the shared configuration
3. Stow the selected profile

### Shared Config

The `shared/` directory contains configuration used by every profile (Neovim, zsh, tmux, Kitty, etc.).

## Greatly Inspired By

1. [josean-dev/dev-environment-files](https://github.com/josean-dev/dev-environment-files)
2. [ThePrimeagen/init.lua](https://github.com/ThePrimeagen/init.lua)
3. [tjdevries/config.nvim](https://github.com/tjdevries/config.nvim)
