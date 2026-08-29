require("render-markdown").setup({
  file_types = { "markdown" },
  completions = { blink = { enabled = true } },

  anti_conceal = {
    enabled = true,
    above = 0,
    below = 0,
  },
  win_options = {
    conceallevel = { default = vim.o.conceallevel, rendered = 3 },
    concealcursor = { default = vim.o.concealcursor, rendered = "" },
  },

  heading = {
    width = "block",
    min_width = 30,
    left_pad = 0,
    right_pad = 2,
    icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
  },
  code = {
    width = "block",
    min_width = 40,
    left_pad = 1,
    right_pad = 2,
    border = "thin",
    language_name = true,
  },
  bullet = {
    icons = { "•", "◦", "▪", "▫" },
  },
  checkbox = {
    unchecked = { icon = "󰄱 " },
    checked = { icon = "󰱒 " },
    custom = {
      todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
      important = { raw = "[!]", rendered = "󰀦 ", highlight = "DiagnosticWarn" },
      forwarded = { raw = "[>]", rendered = "󰜎 ", highlight = "RenderMarkdownTodo" },
      cancelled = { raw = "[~]", rendered = "󰰱 ", highlight = "Comment" },
    },
  },
  link = {
    wiki = { icon = "󱗖 ", highlight = "RenderMarkdownWikiLink" },
  },
  -- images and math are rendered snacks.image
  latex = { enabled = false },
  sign = { enabled = false },
  indent = { enabled = false },
})

vim.keymap.set("n", "<leader>um", "<cmd>RenderMarkdown buf_toggle<CR>",
  { desc = "Toggle markdown rendering", silent = true })
