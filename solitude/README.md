# Solitude Setup

Solitude is a minimal Arch Linux Hyprland profile. It installs Hyprland,
Quickshell, PipeWire, and Steam packages, optionally the NVIDIA drivers, then
deploys the shared and Solitude dotfiles through GNU Stow.

The desktop shell (bar, launcher, clipboard history, notifications, OSD, and
lock screen) is a single Quickshell instance defined in
`.config/quickshell/shell`.

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

The bootstrap asks before installing NVIDIA drivers; the default answer follows
whether `lspci` reports an NVIDIA GPU. Set `SOLITUDE_NVIDIA=y` or `n` to skip
the prompt.

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

This does not install a display manager. Logging in on tty1 starts Hyprland
from `.config/zsh/.zprofile`; the bootstrap also offers getty autologin on tty1
so the machine boots straight into the session (set `SOLITUDE_AUTOLOGIN=y|n` to
skip the prompt). Reboot after bootstrap so the NVIDIA module and service
changes are loaded. To start the session by hand from another TTY use the
official wrapper (it supervises the compositor and handles crash recovery;
running `Hyprland` directly prints a warning):

```bash
start-hyprland
```

## First Session Checks

Run these checks after entering Hyprland:

```bash
hyprctl configerrors
hyprctl monitors
systemctl --user --no-pager --full status pipewire wireplumber
shell shell ping
journalctl --user -t shell -b
nvidia-smi
```

Unknown hostnames use an automatic preferred-mode monitor rule.

Verify these interactions manually:

- `Super+D` opens the launcher; `Super+C` opens clipboard history.
- `Print` saves an area screenshot in `~/Pictures`.
- `Ctrl+Super+L` locks the session.
- `Super+Comma` dismisses the last notification; `Super+Alt+Comma` shows the
  notification history.
- The bar shows workspaces, active window, clock, tray, network, VPN, volume,
  and battery where applicable. `Super+Shift+Space` hides it.
- Steam launches and renders correctly.

Hypridle locks after five minutes of inactivity and turns displays off after
five minutes and thirty seconds. Activity turns the displays back on.

For startup failures, inspect `hyprctl configerrors` and
`journalctl --user -b`. Shell errors are in
`journalctl --user -t shell`; running `qs -c shell` from a terminal
prints QML errors directly. Portal problems are visible with
`systemctl --user status xdg-desktop-portal-hyprland`.

## The Shell

Layout of `.config/quickshell/shell`:

| Path                    | Purpose                                                                                  |
| ----------------------- | ---------------------------------------------------------------------------------------- |
| `shell.qml`             | Root. Instantiates every module and exposes the IPC targets                              |
| `Commons/Config.qml`    | All user settings: font, bar layout, sizes, timeouts                                     |
| `Commons/Theme.qml`     | Palette and spacing tokens; rounding follows Hyprland                                    |
| `Ui/`                   | Overlay, Card, SearchField primitives                                                    |
| `modules/bar`           | Per-monitor bar with workspaces, window title, clock, tray, network, VPN, audio, battery |
| `modules/launcher`      | Application launcher. `>` runs a command, `!` in a terminal, `=` calculator              |
| `modules/clipboard`     | Clipboard history captured by `wl-paste --watch`                                         |
| `modules/keybindings`   | Searchable list of every Hyprland bind; Enter copies the combo                           |
| `modules/notifications` | Notification daemon with toasts and history                                              |
| `modules/menu`          | Command menu dropped from the clock; actions live in `modules/menu/Routes.js`            |
| `modules/osd`           | Volume and brightness overlay                                                            |
| `modules/lock`          | Session lock backed by PAM; runs in a separate instance from `lock.qml`                  |
| `modules/displays`      | Monitor layouts and profiles: a port of omarchy-hyprmoncfg driving `hyprmoncfgd`         |

### New monitors and hyprmoncfg

hyprmoncfgd applies the best-scoring saved profile on every hotplug, and a
profile disables any connected monitor it does not list. On its own that
switches off a monitor you have never configured. `monitor-guard`
(started from `autostart.lua`) prevents it: when an unknown monitor appears it
runs `hyprmoncfg unmanage`, so the monitor comes up with Hyprland's defaults
and a notification tells you to arrange it. Save a profile in the Displays
panel and the guard runs `hyprmoncfg manage` to resume auto-switching. Logs:
`journalctl --user -t monitor-guard`.

A drop-in (`.config/systemd/user/hyprmoncfgd.service.d/shell.conf`) raises
the daemon's hotplug debounce to 3 s so the guard acts first.

Edit `Config.qml` or `Theme.qml`, then `shell shell reload` (file
watching is off; reload is refused while locked). The lock screen runs as a
second Quickshell instance, `lock.qml`, started once by
`launch-shell` and never reloaded, so iterating on the shell cannot
strand a locked session. Control everything from Hyprland binds or a terminal
with `shell`:

```bash
shell shell toggle launcher
shell shell toggle clipboard
shell shell toggle keybindings
shell menu toggle root
shell lock lock
shell notifications dismissAll
shell bar toggle
shell shell reload
```

### The Menu

`Super + Shift + D` (or a middle click on the clock) opens a command menu in
the launcher's frame: one flat list of every action (capture, toggles,
sharing, power) that filters as you type, so "lock" or "screenshot" is Enter
away. Subtitles start with a group name, so typing "toggle" narrows to the
toggles. Keyboard layout and emoji are the only nested routes: `Super + Alt +
K` and `Super + E`. The same key closes the picker again.

### Widget panels

Every right-dock widget (and the wifi bubble) opens the same way the clock
does: the dock itself morphs into a card, its icons stay along the top and
clicking another one swaps the content in place. Escape, Tab or a click
elsewhere closes it. The right dock shows system, audio and battery by
default and unfolds tray, displays, bluetooth, VPN and windows to its left
while hovered; `Config.bar.right` and `rightMore` pick the split.

### The center panel

Left-clicking the clock morphs its bubble into a panel with three tabs:
calendar, theme switcher, background switcher. Theme and background are
carousels: the centred tile is the selection, arrows or the wheel move it,
Enter or a click applies. `Super + Shift + Ctrl + Space` opens on themes,
`Super + Ctrl + Space` on backgrounds, Tab cycles the tabs, Escape closes.
From a terminal: `shell center toggle theme`.

Rows are data in `modules/menu/Routes.js`. A row either names a command or
pushes a picker route, and can declare `requires: "<command>"` — rows whose
command is not installed are left out, so the menu offers what the machine can
actually do.

Keybinding search is its own overlay, `Super + Ctrl + K`, in the launcher's
frame rather than the menu's: type part of a description or combo, Enter
copies the combo.

The helper commands the routes and the capture binds drive live in
`.local/bin`:

| Command        | What it does                                                        |
| -------------- | ------------------------------------------------------------------- |
| `screenshot`   | Region or fullscreen capture; the toast opens satty when clicked    |
| `screenrecord` | Starts a `wf-recorder` capture, or stops the running one            |
| `ocr`          | Copies the text out of a region with tesseract                      |
| `toggle`       | Starts or stops hypridle (idle locking) or hyprsunset (nightlight)  |
| `keybindings`  | Prints every Hyprland bind as rows for the keybindings overlay      |
| `emoji`        | Prints emoji as menu rows, built from Python's Unicode database     |
| `share`        | Sends the clipboard, files, or a folder with LocalSend              |
| `transcode`    | Re-encodes a picture or video (ported from omarchy-transcode)       |
| `theme`        | Switches the palette and window border colors                       |
| `background`   | Sets the wallpaper with swaybg                                      |
| `keyboard`     | Switches, adds and removes keyboard layouts                         |
| `windows-vm`   | Windows VM via dockur/windows + RDP; `windows` bar widget drives it |
| `windows-key`  | Prints the OEM Windows product key from the firmware MSDM table     |

### Themes

A theme is a directory in `.config/shell/themes/<name>`:

```
colors.json     palette read by Commons/Theme.qml
hyprland.lua    window border colors, loaded by hyprland.lua
preview.png     thumbnail shown in the Theme menu (optional)
backgrounds/    wallpapers offered by the background menu
```

Adding a theme is dropping a directory in there: `colors.json` is the only
required file. Wallpapers are any images in `backgrounds/` — jpg, png and webp
all work. `preview.png` is what the Theme menu shows as a tile; a screenshot of
the desktop is the obvious thing to use, and a theme without one still lists,
just with its glyph instead of a picture.

Both menus show previews rather than a list of names. The images are decoded
once into 600x400 JPEG thumbnails cached in
`~/.local/state/shell/thumbnails`, keyed by path and mtime — that keeps a
2880px wallpaper from being decoded per tile, and sidesteps Qt needing an extra
plugin to read webp. Replacing an image under the same name re-renders it;
deleting the cache directory is always safe.

`kanagawa` and `solitude` ship here, both taken from omarchy. Switch with
`Super + Shift + Ctrl + Space`, the Style route in the menu, or
`theme set kanagawa`. The shell repaints without a reload: `Theme.qml`
watches the state file. Colors not named in `colors.json` fall back to the
values in `Theme.qml`, so a partial theme is fine.

Backgrounds come from every installed theme, not just the active one
(`Super + Ctrl + Space`). Setting a theme only changes the wallpaper if the
current one belonged to a different theme, so a background you picked by hand
survives a theme switch.

### Keyboard layouts

The session ships `us,latam`. The list is state, not config —
`~/.local/state/shell/keyboard-layouts`, read by `hypr/input.lua` — because
`/etc/vconsole.conf` holds one console keymap and cannot express a session
list. `/etc/vconsole.conf` only wins if it names more than one layout itself.

```bash
keyboard next          # cycle; Left Alt + Space does the same
keyboard set latam
keyboard add fr        # appends and reloads Hyprland
keyboard remove fr
```

Switching between configured layouts is instant; adding or removing one needs
the reload the script does for you. `Super + Alt + K` opens the Keyboard route
in the menu. The first layout in the list is what keybindings resolve against,
so keep a Latin one leading.

### VPN

The widget drives strongSwan through `swanctl`. Describe the tunnel in
`/etc/swanctl/conf.d/<name>.conf`, then run `vpn setup` once: it writes
`/etc/sudoers.d/shell-vpn` allowing only the exact `swanctl` and
`systemctl` command lines the script uses, with initiate and terminate
entries generated per connection name. Re-run it after adding a
connection. Nothing about the tunnel is stored by the shell; the name,
virtual IP and gateway are read live and shown only in the bar and panel.

Left click on the widget opens the panel; middle or right click toggles the
tunnel. `Config.vpn.connection` picks which connection when more than one is
configured; empty means the first one `swanctl --list-conns` reports.

### Windows VM

The `windows` bar widget drives a Windows guest running in Docker through
`windows-vm` (a trim of omarchy-windows-vm). It hides itself until the
VM is installed. Disk lives in `~/.windows`, `~/Windows` is shared into the
guest, config and RDP credentials in `~/.config/windows`.

```bash
windows-vm install     # picks RAM/CPU/disk, edition, user; offers the firmware OEM key
windows-vm launch      # start if needed, RDP fullscreen, stop on exit (-k keeps it up)
windows-vm toggle      # what the bar widget calls
windows-vm state       # STATE  DETAIL  (unavailable|off|booting|up)
shell bar openPanel windows
```

Left click opens the panel (switch, RDP, web console on `127.0.0.1:8006`, log);
middle or right click starts or stops the VM. Stop only through the script or
the widget: it sends ACPI shutdown and waits up to two minutes. After a host
crash, look at the web console before assuming the disk is gone; Windows may
be in repair or chkdsk and RDP comes up late. `~/.windows` is btrfs, so
`cp --reflink=always ~/.windows/data.img ~/.windows/data.img.bak` is a free
snapshot.

### Learning the shell

`docs/qml-guide.md` is a guide to QML and Quickshell written against this
code — how the runtime works, how bindings and singletons behave here, and a
step-by-step exercise for the animation work — the menu now has those
animations, so the guide doubles as a walkthrough of the code that is there.

Restart the shell after larger changes with `launch-shell --restart`
(`--restart-lock` restarts the lock instance, refused while locked).

If Hyprland ever shows its "lockscreen app died" screen, unlock from another
TTY with `hyprctl eval 'hl.clear_crashed_lockscreen()'`.

## Remove Or Roll Back

From the repository, remove the deployed links with:

```bash
stow -D --no-folding -t "$HOME" solitude shared
```

Then restore the wanted files from the backup directory printed by the
bootstrap. Package and service changes are not reverted automatically.
