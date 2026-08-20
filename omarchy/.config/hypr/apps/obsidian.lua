hl.window_rule({
  name = "obsidian-on-ws3",
  match = { class = "^(md\\.obsidian\\.Obsidian|obsidian).*" },
  workspace = "3 silent"
})

o.window("^(md\\.obsidian\\.Obsidian|obsidian).*", { focus_on_activate = false })
