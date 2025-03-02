# My dotfiles

This directory contains my dotfiles (use at your own risk)

## Requirements

Ensure you have the following installed on your system:

```Bash
sudo apt install git
sudo apt install stow
```

### Terminal

Configuration for Wezterm, Alacritty, Tmux (terminal multiplexer) and Ghostty btw.

- https://alacritty.org/
- https://wezfurlong.org/wezterm/index.html
- https://ghostty.org

### Shell

Configuration for Bash, Fish and Zsh.

### Window Manager

Sway with Waybar and i3 with i3status.

### Editor

Neovim:

- https://neovim.io

## Installation

To install and set the dotfiles in a new machine clone the repo inside `$HOME` **(personal preference and makes it easy to work with `stow`)**:

```Bash
git clone git@github.com:MoXcz/dotfiles.git
cd dotfiles
./scripts/sway_i3
```

#### Script

Select `Run All` on the menu that appears (if `bemenu` is not installed run `run_bak.sh`; should be installed if running the installation script for sway first):
```Bash
scripts/run.sh
```

Then, use GNU stow to create symlinks

```Bash
stow .
```

## Greatly Inspired by

1. https://github.com/josean-dev/dev-environment-files
2. https://github.com/ThePrimeagen/init.lua
3. https://github.com/tjdevries/config.nvim
