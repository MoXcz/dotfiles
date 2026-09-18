# Hermit Setup

Hermit is a minimal Arch Linux Hyprland profile built from plain, separate
programs rather than one desktop shell. It is Solitude without Quickshell:
the same Hyprland configuration, scripts, themes and backgrounds, with the
bar, launcher, notifications, OSD, clipboard history and lock screen each
handled by a small tool that does only that.

| Role             | Program                                                                     |
| ---------------- | --------------------------------------------------------------------------- |
| Compositor       | Hyprland (Lua config in `.config/hypr`)                                     |
| Bar              | [Waybar](https://github.com/Alexays/Waybar)                                 |
| Launcher, menus  | [rofi](https://github.com/davatorium/rofi) through the `menu` script        |
| Notifications    | [mako](https://github.com/emersion/mako)                                    |
| Volume, bright.  | [swayosd](https://github.com/ErikReider/SwayOSD)                            |
| Clipboard        | [cliphist](https://github.com/sentriz/cliphist) + rofi (`clipboard`)        |
| Lock, idle       | hyprlock, hypridle                                                          |
| Wallpaper        | swaybg (`background`)                                                       |
| Wi-Fi            | NetworkManager, `nmtui` in a floating terminal                              |
| Bluetooth        | bluez, `bluetui` in a floating terminal                                     |
| Audio            | PipeWire, `wiremix` in a floating terminal                                  |
| Screen sharing   | xdg-desktop-portal-hyprland, picker from hyprland-guiutils                  |
| File pickers     | xdg-desktop-portal-gtk                                                      |
| File manager     | nemo                                                                        |
| Removable drives | udiskie                                                                     |
| Monitors         | `hypr/monitors.lua` with per-host layouts                                   |
| Auth prompts     | polkit-gnome                                                                |

## Install

Install Arch the same way as [Solitude](../solitude/README.md#install-arch),
then:

```bash
curl -fsSL https://raw.githubusercontent.com/MoXcz/dotfiles/main/hermit/bootstrap.sh | bash
```

`bootstrap.sh` enables multilib, installs the packages above, builds `yay`,
installs the AUR extras (Iosevka Term, LocalSend, Zen), asks
about the NVIDIA drivers and tty1 autologin, enables NetworkManager,
bluetooth and PipeWire, backs up any existing config and stows `shared` plus
`hermit`.

Environment overrides for a non-interactive run:

- `HERMIT_NVIDIA=y|n`
- `HERMIT_AUTOLOGIN=y|n`
- `DOTFILES_DIR=/path/to/checkout`

## Keys

`Super + Ctrl + K` opens a searchable list of every binding. The ones worth
knowing on day one:

| Keys                        | Action                                    |
| --------------------------- | ----------------------------------------- |
| `Super + Return`            | Terminal                                  |
| `Super + D`                 | Application launcher                      |
| `Super + Shift + D`         | Command menu (capture, toggles, theme, …) |
| `Super + Shift + Q`         | Power menu                                |
| `Super + C`                 | Clipboard history                         |
| `Super + E`                 | Emoji picker                              |
| `Super + A` / `B` / `W`     | Audio / Bluetooth / Wi-Fi                 |
| `Super + S`                 | System monitor                            |
| `Super + Ctrl + L`          | Lock                                      |
| `Super + Shift + Space`     | Hide or show the bar                      |
| `Super + Ctrl + Space`      | Background switcher                       |
| `Super + Shift + Ctrl + Space` | Theme switcher                         |
| `Print` / `Super + Shift + S` | Screenshot region                       |
| `Alt + Print`               | Screen recording (again to stop)          |
| `Super + Ctrl + Print`      | OCR a region to the clipboard             |
| `Super + ,`                 | Dismiss notification                      |
| `Super + Ctrl + ,`          | Do not disturb                            |
| `Super + Alt + ,`           | Open the last notification's action       |

## Themes

A theme is a folder under the shared `.config/themes/<name>` with:

- `colors.json` – twelve named colors
- `hyprland.lua` – optional window border colors

Wallpapers live independently under `~/backgrounds`, stowed from the shared
dotfiles package.

`theme set <name>` renders `colors.json` into a `theme.*` file next to the
config of waybar, mako, rofi and hyprlock (those files are generated, not
stowed), copies `hyprland.lua` into `~/.local/state/hermit`, and reloads
what is running. `theme apply` runs at every session start so the includes
exist before waybar and mako read them.

## Scripts

Everything lives in `.local/bin`:

| Script            | Purpose                                                      |
| ----------------- | ------------------------------------------------------------ |
| `menu`            | rofi menus: launcher, capture, toggle, theme, power, …       |
| `clipboard`       | cliphist picker (`clipboard wipe` clears the history)        |
| `emoji`           | emoji picker, copies and types the selection                 |
| `keybindings`     | searchable list of Hyprland bindings                         |
| `tui <cmd>`       | run a TUI in a floating terminal, or focus the open one      |
| `lock`            | hyprlock, no-op while already locked                         |
| `toggle`          | `idle`, `nightlight`, `dnd`, `bar`                            |
| `theme`           | `current`, `list`, `set`, `next`, `apply`                    |
| `background`      | `current`, `list`, `set`, `next`, `restore`                  |
| `keyboard`        | layout list, switch, add, remove                             |
| `screenshot`      | region or full screen; click the toast to edit in satty      |
| `screenrecord`    | wf-recorder toggle                                           |
| `ocr`             | tesseract on a region                                        |
| `transcode`       | resize and re-encode pictures and videos                     |
| `share`           | LocalSend for the clipboard, files or a folder               |
| `vpn`             | strongSwan helper (`vpn setup` once)                         |
| `windows-vm`      | dockur/windows VM helper                                     |
