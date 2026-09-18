vim.opt.rtp:prepend(vim.fn.expand("~/workspace/github.com/knapp.nvim"))

require("knapp").setup({
  vault = "~/workspace/notes",
  ignore = { ".obsidian", ".obsidian-mobile", ".trash", ".git", ".stfolder", ".pi", "site" },
  wrap = {
    enabled = true,
    width = 120,
    pad = false,
    display_line_motions = true,
  },
  backlinks = {
    auto = true,
    position = "right",
    width = 80,
    height = 10,
  },
  keys = {
    swap_ci = false,
  },
})
