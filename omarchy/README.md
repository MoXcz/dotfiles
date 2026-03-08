# Omarchy setup

This repository contains my dotfiles and scripts for configuring an Arch Linux system with the Omarchy environment.

The setup process consists of three main steps:

1. Install Arch Linux
2. Install Omarchy
3. Run the bootstrap script

## Install Arch Linux

- Arch Linux Installation Guide [https://wiki.archlinux.org/title/Installation_guide](https://wiki.archlinux.org/title/Installation_guide)
- Arch Linux ISO: [https://archlinux.org/download/](https://archlinux.org/download/)
- I prefer a manual installation, but Omarchy has some recommendations: [https://learn.omacom.io/2/the-omarchy-manual/96/manual-installation](https://learn.omacom.io/2/the-omarchy-manual/96/manual-installation)

Boot from the drive and run `archinstall`. If you need wifi:
```sh
iwctl
> station wlan0 scan
> station wlan0 connect <network>
```

## Install Omarchy

```sh
curl -fsSL https://omarchy.org/install | bash
```

Repository: [https://github.com/basecamp/omarchy](https://github.com/basecamp/omarchy)

## Run the Bootstrap Script

Once Omarchy is installed, run the bootstrap script to install packages and deploy dotfiles.

```bash
curl -fsSL https://raw.githubusercontent.com/MoXcz/dotfiles/main/omarchy/bootstrap.sh | bash
```

