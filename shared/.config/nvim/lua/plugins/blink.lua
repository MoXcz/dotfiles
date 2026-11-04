vim.g.blink_manual = false

require("blink-cmp").setup({
  fuzzy = { implementation = "prefer_rust" },
  signature = { enabled = true, window = { show_documentation = false } },
  cmdline = {
    enabled = true,
    completion = { menu = { auto_show = true } },
  },
  keymap = {
    preset = "default",
    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-d>"] = { "show_documentation", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
  },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    menu = {
      auto_show = function() return not vim.g.blink_manual end,
      scrolloff = 1,
      scrollbar = false,
      draw = {
        treesitter = { "lsp" },
        columns = {
          { "kind_icon" },
          { "label", "label_description", gap = 1 },
          { "kind" },
        },
      },
    },
    list = { selection = { preselect = true, auto_insert = false } },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 300,
      window = { scrollbar = false },
    },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
})

Snacks.toggle
  .new({
    name = "Auto Completion",
    get = function() return not vim.g.blink_manual end,
    set = function(state) vim.g.blink_manual = not state end,
  })
  :map("<leader>uk")
