-- Floating windows: dialogs, previewers, TUIs opened by `tui`, media viewers.
o.window({ tag = "floating-window" }, { float = true, center = true, size = { 875, 600 } })

o.window(
  "(org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|TUI.float|imv|mpv)",
  { tag = "+floating-window" }
)

-- The portal only ever shows dialogs (file pickers, screen shares, permission
-- prompts), so every one of its windows floats, whatever the caller titled it.
o.window("xdg-desktop-portal-gtk", { tag = "+floating-window" })
o.window({
  class = "(sublime_text|DesktopEditors|org.gnome.Nautilus)",
  title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
}, { tag = "+floating-window" })

o.window("org.gnome.Calculator", { float = true })
o.window("omacalc", { float = true })
o.window("dev.tensaku.Tensaku", { float = true, center = true })

-- Media apps opt out of the default opacity (see windows.lua).
o.window(
  "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
  { tag = "-default-opacity", opacity = "1 1" }
)

-- Tags an app can set on itself.
o.window({ tag = "pop" }, { rounding = 8 })
o.window({ tag = "noidle" }, { idle_inhibit = "always" })
