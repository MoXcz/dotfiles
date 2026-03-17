require('blink-cmp').setup({
  fuzzy = { implementation = 'prefer_rust' },
  signature = { enabled = true },
  cmdline = {
    enabled = true,
    completion = { menu = { auto_show = true } },
  },
  keymap = {
    ["<C-d>"] = { "show_documentation", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
  },
  appearance = {
    use_nvim_cmp_as_default = false,
    nerd_font_variant = 'mono',
  },
  completion = {
    trigger = { show_on_trigger_character = true },
    documentation = {
      auto_show = false,
      window = {
        border = nil,
        scrollbar = false,
        winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
      },
    },
    menu = {
      border = nil,
      scrolloff = 1,
      scrollbar = false,
      draw = {
        columns = {
          { 'kind_icon' },
          { 'label',      'label_description', gap = 1 },
          { 'kind' },
          { 'source_name' },
        },
      },
    },
  },
  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' }, },
})
