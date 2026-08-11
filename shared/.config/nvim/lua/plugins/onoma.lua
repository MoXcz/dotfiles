local Snacks = require("snacks")

require("onoma").setup({
  picker = { 'snacks' },
})

-- cd ~/.local/share/nvim/site/pack/core/opt/onoma.nvim && cargo --config ./bridge/.cargo/config.toml build --release --manifest-path ./bridge/Cargo.toml
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>fa', Snacks.picker.get_symbols, { desc = 'Symbols', silent = true })
