# My dotfiles

(Use at your own risk!)
This directory contains my dotfiles

## Requirements

Ensure you have the following installed on your system:

```Bash
sudo apt install git
sudo apt install stow
```

### Terminal

Configuration for Wezterm and Alacritty.

- https://alacritty.org/
- https://wezfurlong.org/wezterm/index.html

## Installation

#### Ansible Installation

[Here](https://github.com/MoXcz/dotfiles/tree/main/ansible) are the instructions for an automated installation in my system (Debian 12)

#### Manual Installation

To install and set the dotfiles in a new machine clone the repo inside $HOME folder **(personal preference)**

```Bash
git clone git@github.com:MoXcz/dotfiles.git
cd dotfiles
```

Then use GNU stow to create symlinks

```Bash
stow .
```

## Greatly Inspired by

1. https://github.com/josean-dev/dev-environment-files
2. https://github.com/ThePrimeagen/init.lua
3. https://github.com/tjdevries/config.nvim
