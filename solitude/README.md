# Solitude Setup

Solitude is a minimal Arch Linux Hyprland profile. It installs
Hyprland, Waybar, Walker, Hyprlock, PipeWire, Steam, and NVIDIA packages, then
deploys the shared and Solitude dotfiles through GNU Stow.

## Install Arch

1. Download the current [Arch Linux ISO](https://archlinux.org/download/) and boot it in UEFI mode.
2. Confirm the system clock and internet connection:

```bash
timedatectl set-ntp true
ping -c 3 archlinux.org
```

3. For Wi-Fi, connect with `iwctl` before starting the installer:

```text
iwctl
station wlan0 scan
station wlan0 get-networks
station wlan0 connect YOUR_NETWORK
exit
```

4. Start the guided installer:

```bash
  archinstall
```

5. Recommended for the following options. Leave unlisted settings at their defaults
   unless hardware or disk layout require otherwise.

| Section                  | Recommended choice                                                                                            |
| ------------------------ | ------------------------------------------------------------------------------------------------------------- |
| Mirrors and repositories | Select a nearby region.                                                                                       |
| Disk configuration       | Use the guided default layout on the intended disk.                                                           |
| File system              | Btrfs with the default subvolume layout and compression is recommended for snapshots; ext4 is also supported. |
| Disk encryption          | LUKS is strongly recommended for laptops and personal systems. Keep the recovery information safe.            |
| Bootloader               | Select a UEFI-compatible bootloader offered by your current `archinstall` release.                            |
| Kernel                   | `linux` or `linux-lts`.                                                                                       |
| Hostname and timezone    | Set both for the machine and location.                                                                        |
| Root password            | Set a recovery password and store it securely.                                                                |
| User account             | Create your normal user and mark it as a superuser.                                                           |
| Audio                    | PipeWire. The bootstrap also installs the required user services.                                             |
| Network configuration    | Copy the ISO network configuration, or select NetworkManager.                                                 |
| Profile                  | Do not select a desktop environment or window-manager profile; Solitude installs Hyprland itself.             |
| Additional packages      | Add `git` if it is not already included; it is needed to clone this repository.                               |

6. Install and reboot. Log in as the normal user created above.

### Secure Boot And NVIDIA

NVIDIA modules must be trusted by Secure Boot. If Secure Boot is enabled, enroll
and use your own signing key before relying on the NVIDIA driver, or temporarily
disable Secure Boot for the initial setup. The bootstrap does not edit kernel
parameters, sign modules, or configure early KMS. Test the installed driver
after rebooting with `nvidia-smi`.

## Install Solitude

Review the repository first when possible, then run the bootstrap from a TTY:

```bash
sudo pacman -Syu --needed git
git clone https://github.com/MoXcz/dotfiles ~/dotfiles
cd ~/dotfiles
./solitude/bootstrap.sh
```

To grab the bootstrap file quickly:

```bash
curl -fsSL https://raw.githubusercontent.com/MoXcz/dotfiles/main/solitude/bootstrap.sh | bash
```

This does not install a display manager. Reboot after bootstrap so the NVIDIA
module and service changes are loaded, log in on a TTY, and start the session:

```bash
Hyprland
```

## First Session Checks

Run these checks after entering Hyprland:

```bash
hyprctl configerrors
hyprctl monitors
systemctl --user --no-pager --full status pipewire wireplumber
pgrep -a waybar
nvidia-smi
```

Unknown hostnames use an automatic preferred-mode monitor rule.

Verify these interactions manually:

- `Super+D` opens Walker; `Super+C` opens clipboard history.
- `Print` saves an area screenshot in `~/Pictures`.
- `Ctrl+Super+L` displays Hyprlock.
- Waybar shows workspaces, clock, tray, network, volume, memory, and battery
  where applicable.
- Steam launches and renders correctly.

Hypridle locks after five minutes of inactivity and turns displays off after
five minutes and thirty seconds. Activity turns the displays back on.

For startup failures, inspect `hyprctl configerrors` and
`journalctl --user -b`. Run `walker` or `waybar` from a terminal to expose
provider or configuration errors. Portal problems are visible with
`systemctl --user status xdg-desktop-portal-hyprland`.

## Remove Or Roll Back

From the repository, remove the deployed links with:

```bash
stow -D --no-folding -t "$HOME" solitude shared
```

Then restore the wanted files from the backup directory printed by the
bootstrap. Package and service changes are not reverted automatically.
