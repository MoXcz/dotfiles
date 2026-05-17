hl.window_rule({
  name = "obsidian-on-ws3",
  match = { class = "^(obsidian).*" },
  workspace = "3 silent"
})

o.window("^(obsidian).*", { focus_on_activate = false })
