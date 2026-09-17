-- Shell surfaces pop without compositor layer fades.
hl.layer_rule({ match = { namespace = "^(rofi|notifications|swayosd)$" }, no_anim = true, animation = "none" })
-- Waybar is not a layer to blur; everything drawn behind it stays crisp.
hl.layer_rule({ match = { namespace = "^waybar$" }, no_anim = true })
