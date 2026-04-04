# Omarchy Setup

Arch Linux desktop configuration built on top of [Omarchy](https://omarchy.org/).

![Setup Preview](./setup.png)

## Stack

| Component   | Software                                                                              |
| ----------- | ------------------------------------------------------------------------------------- |
| OS          | [Arch Linux](https://archlinux.org/)                                                  |
| Meta-config | [Omarchy](https://omarchy.org/)                                                       |
| WM          | [Hyprland](https://github.com/hyprwm/Hyprland)                                        |
| Terminal    | [tmux](https://github.com/tmux/tmux) inside [Kitty](https://sw.kovidgoyal.net/kitty/) |
| Bar         | [Waybar](https://github.com/Alexays/Waybar)                                           |
| Launcher    | [Walker](https://github.com/abenz1267/walker)                                         |
| Shell       | [Zsh](https://www.zsh.org/)                                                           |
| Editor      | [Neovim](https://neovim.io/)                                                          |
| Font        | [Iosevka Term](https://typeof.net/Iosevka/)                                           |
| Colorscheme | [Kanagawa](https://github.com/rebelot/kanagawa.nvim)                                  |

## Installation

### Prerequisites

- Arch Linux installed
- [Omarchy](https://omarchy.org/) installed
- Internet connection

### One-Liner

After installing Arch and Omarchy, run the bootstrap script:

```bash
curl -fsSL https://raw.githubusercontent.com/MoXcz/dotfiles/main/omarchy/bootstrap.sh | bash
```

### Manual Steps

If you prefer to do it step by step:

#### 1. Install Arch Linux

- [Official Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [Arch ISO](https://archlinux.org/download/)
- [Omarchy Manual Install Recommendations](https://learn.omacom.io/2/the-omarchy-manual/96/manual-installation)

For WiFi during install:

```sh
iwctl
> station wlan0 scan
> station wlan0 connect <network>
```

#### 2. Install Omarchy

```sh
curl -fsSL https://omarchy.org/install | bash
```

- Repository: [basecamp/omarchy](https://github.com/basecamp/omarchy)

#### 3. Clone and Bootstrap

```bash
git clone https://github.com/MoXcz/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh omarchy
```

Or use `bootstrap.sh` which handles cloning, removing conflicting configs, deploying with Stow, and installing packages in one go.

## Packages Installed by Bootstrap

The bootstrap script installs the following via `yay`:

| Package                | Purpose                           |
| ---------------------- | --------------------------------- |
| `zsh`                  | Shell                             |
| `zen-browser`          | Web browser                       |
| `syncthing`            | File synchronization              |
| `tmux`                 | Terminal multiplexer              |
| `protonplus`           | Proton/compatibility tool manager |
| `ghostty`              | GPU-accelerated terminal          |
| `ttf-iosevka-term`     | Iosevka terminal font             |
| `ttf-iosevkaterm-nerd` | Iosevka Nerd Font variant         |
| `sioyek`               | PDF viewer                        |
| `nemo`                 | File manager                      |
