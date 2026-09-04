-- Shell surfaces pop without compositor layer fades.
hl.layer_rule({ match = { namespace = "^shell-(bar|launcher|clipboard|keybindings|menu|notifications|notification-history|osd|center|dock-panel)$" }, no_anim = true, animation = "none" })
