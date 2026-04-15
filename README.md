# My Dotfiles

Personal configuration files for Linux desktop environments, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Installation](#installation)
- [Profiles](#profiles)

## Overview

This repository contains two distinct desktop environment profiles, plus a set of shared configurations used by both.

| Profile                               | Base OS    | WM        |
| ------------------------------------- | ---------- | --------- |
| [**Omarchy**](./omarchy/)             | Arch Linux | Hyprland  |
| [**Paradise Lost**](./paradise-lost/) | Debian 12  | Sway / i3 |

Both profiles share:

- **Shell**: [Zsh](https://www.zsh.org/)
- **Terminal**: [Ghostty](https://ghostty.org/) / [Kitty](https://sw.kovidgoyal.net/kitty/) with [tmux](https://github.com/tmux/tmux)
- **Editor**: [Neovim](https://neovim.io/)
- **Font**: [Iosevka Term](https://typeof.net/Iosevka/)
- **Colorscheme**: [Kanagawa](https://github.com/rebelot/kanagawa.nvim) (though not completely)
- **Bar**: [Waybar](https://github.com/Alexays/Waybar)

## Directory Structure

```
.
├── setup.sh            # Main entry point — stows a selected profile
├── shared/             # Config shared between all profiles
│   ├── .config/        # Neovim, Zsh, Tmux, Ghostty, Starship, etc.
│   └── scripts/        # Utility scripts (sessionizer, cht.sh, …)
├── omarchy/            # Arch Linux + Hyprland + Omarchy profile
│   ├── bootstrap.sh    # Post-install script
│   └── .config/        # Hyprland, Alacritty, Waybar, …
└── paradise-lost/      # Debian 12 + Sway/i3 profile
    ├── scripts/        # Setup & utility scripts
    └── .config/        # Sway, i3, Waybar, i3blocks, …
```

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

You can also pass the profile name directly:

```bash
./setup.sh omarchy
./setup.sh paradise-lost
```

## Profiles

### Omarchy

> Arch Linux + Hyprland via [Omarchy](https://omarchy.org/)

See [omarchy/README.md](./omarchy/README.md) for detailed setup instructions.

### Paradise Lost

> Debian 12 + Sway / i3

See [paradise-lost/README.md](./paradise-lost/README.md) for detailed setup instructions.

### Shared Config

The `shared/` directory contains configuration used by both profiles (Neovim, zsh, tmux, Kitty, etc.).

## Greatly Inspired By

1. [josean-dev/dev-environment-files](https://github.com/josean-dev/dev-environment-files)
2. [ThePrimeagen/init.lua](https://github.com/ThePrimeagen/init.lua)
3. [tjdevries/config.nvim](https://github.com/tjdevries/config.nvim)
