return {
  {
    'neanias/everforest-nvim',
    enabled = false,
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      vim.cmd('colorscheme everforest')
      vim.cmd.hi('Comment gui=none')

      -- In theory, it makes the background transparent.
      vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
      vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
    end,
  },
  {
    'folke/tokyonight.nvim',
    enabled = false,
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      vim.cmd.colorscheme('tokyonight-night')
      vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
      vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

      -- You can configure highlights by doing something like:
      vim.cmd.hi('Comment gui=none')
    end,
  },
  {
    'rebelot/kanagawa.nvim',
    init = function()
      vim.cmd.colorscheme('kanagawa-dragon')
      vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
      vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

      -- You can configure highlights by doing something like:
      vim.cmd.hi('Comment gui=none')
    end,
  },
}
