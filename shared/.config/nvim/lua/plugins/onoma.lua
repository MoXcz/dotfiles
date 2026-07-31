local Snacks = require("snacks")

require("onoma").setup({
  picker = { 'snacks' },
})

vim.keymap.set({ 'n', 'v', 'x' }, '<leader>fa', Snacks.picker.get_symbols, { desc = 'Symbols', silent = true })
