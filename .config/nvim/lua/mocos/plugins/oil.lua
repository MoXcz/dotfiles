return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup({
        columns = { 'icon' },
        keymaps = {
          ['<C-h>'] = false,
          ['<C-l>'] = false,
          ['<C-k>'] = false,
          ['<C-j>'] = false,
          ['<M-h>'] = 'actions.select_split',
        },
        float = {
          padding = 2,
          max_width = 90,
          max_height = 0,
          win_options = {
            winblend = 0,
          },
        },
        view_options = {
          show_hidden = true,
        },
      })

      -- Open parent directory in current window
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open in current directory' })
      -- Open parent directory in floating window
      -- vim.keymap.set("n", "<leader>-", require("oil").toggle_float)
    end,
  },
}
