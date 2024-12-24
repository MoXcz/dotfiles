return {
  -- Better menu
  { 'stevearc/dressing.nvim', event = 'VeryLazy' },
  -- Git symbols at the left
  { 'lewis6991/gitsigns.nvim', opts = {}, },
  -- Markdown renderer for md files
  { 'MeanderingProgrammer/render-markdown.nvim', opts = {}, dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, },
  -- A tree of all the changes made inside a buffer
  { 'mbbill/undotree', config = function() vim.keymap.set('n', '<leader>ut', vim.cmd.UndotreeToggle) end, },
  ui = { icons = vim.g.have_nerd_font and {} or {}, },
}
