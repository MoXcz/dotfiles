# Paradise Lost

Debian 12 desktop configuration using Sway/i3 window managers.

![Setup Preview](./setup.png)

## Stack

| Component | Software                                                                                     |
| --------- | -------------------------------------------------------------------------------------------- |
| OS        | [Debian 12 (Bookworm)](https://www.debian.org/releases/bookworm/)                            |
| WM        | [Sway](https://swaywm.org/) / [i3](https://i3wm.org/)                                        |
| Terminal  | [tmux](https://github.com/tmux/tmux) inside [Kitty](https://sw.kovidgoyal.net/kitty/)        |
| Bar       | [Waybar](https://github.com/Alexays/Waybar) / [i3blocks](https://github.com/vivien/i3blocks) |
| Launcher  | [bemenu](https://github.com/Cloudef/bemenu)                                                  |
| Shell     | [Zsh](https://www.zsh.org/)                                                                  |
| Editor    | [Neovim](https://neovim.io/)                                                                 |
| Font      | [Iosevka Term](https://typeof.net/Iosevka/)                                                  |

## Installation

### Prerequisites

- Debian 12 (Bookworm) or compatible
- Git
- GNU Stow

```bash
sudo apt install git stow
```

### Quick Setup

From the repository root:

```bash
./setup.sh paradise-lost
```

### Interactive Setup

Run the interactive script to select and run individual setup steps:

```bash
./paradise-lost/scripts/run.sh
```

Select `Run All` to execute every setup script, or pick individual ones.

If `bemenu` is not installed, use the fallback script:

```bash
./paradise-lost/scripts/run_bak.sh
```

With dry-run mode:

```bash
./paradise-lost/scripts/run_bak.sh --dry
```

With filtering (only run scripts matching a pattern):

```bash
./paradise-lost/scripts/run_bak.sh sway
```

### Manual Stow

```bash
stow paradise-lost
```

## Waybar

The Waybar configuration is inspired by:

1. [Jan-Aarela/.dotfiles](https://github.com/Jan-Aarela/.dotfiles)
2. [sejjy/mechabar](https://github.com/sejjy/mechabar)

## Greatly Inspired By

1. [josean-dev/dev-environment-files](https://github.com/josean-dev/dev-environment-files)
2. [ThePrimeagen/init.lua](https://github.com/ThePrimeagen/init.lua)
3. [tjdevries/config.nvim](https://github.com/tjdevries/config.nvim)
