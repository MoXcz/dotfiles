# My dotfiles

![image](./setup.png)

- OS: Debian 12 Bookworm
- WM: [Sway](https://swaywm.org/) or [i3](https://i3wm.org/)
- Terminal: [Tmux](https://github.com/tmux/tmux) inside [Ghostty](https://ghostty.org/)
- Bar: [Waybar](https://github.com/Alexays/Waybar)
- Shell: [Zsh](https://www.zsh.org/)
- Editor: [Neovim](https://neovim.io/)
- Font: Iosevka [Term](https://typeof.net/Iosevka/)
- Colorscheme: [Kanagawa](https://github.com/rebelot/kanagawa.nvim)

## Requirements

Ensure you have the following installed on your system:

- [Stow](https://www.gnu.org/software/stow/)
- Git

For my system (which uses `apt`):

```Bash
sudo apt install git
sudo apt install stow
```

## Installation

To install and set the dotfiles in a new machine clone the repo inside `$HOME` **(personal preference and makes it easy to work with `stow`)**:

```Bash
git clone https://github.com/MoXcz/dotfiles
cd dotfiles
./scripts/runs/sway_i3
./scripts/run.sh
```

#### Script

Select `Run All` on the menu that appears (if `bemenu` is not installed run `run_bak.sh`; should be installed if running the installation script for sway first):

Then, use GNU stow to create symlinks

```Bash
stow .
```

## Greatly Inspired by

1. https://github.com/josean-dev/dev-environment-files
2. https://github.com/ThePrimeagen/init.lua
3. https://github.com/tjdevries/config.nvim
