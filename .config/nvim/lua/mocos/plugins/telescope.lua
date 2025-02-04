return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    require('telescope').setup({
      pickers = {
        find_files = { theme = 'ivy' },
        oldfiles = { theme = 'ivy' },
        live_grep = { theme = 'dropdown' },
        diagnostics = { theme = 'dropdown' },
      },
      extensions = {
        fzf = {},
      },
    })

    local builtin = require('telescope.builtin')
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    local set = vim.keymap.set
    set('n', '<leader>ff', builtin.find_files, {})
    set('n', '<leader>fr', builtin.oldfiles, { desc = 'Recent files' })
    set('n', '<leader>fs', builtin.live_grep, { desc = 'Search for a String' })
    set('n', '<C-g>', builtin.git_files, { desc = 'Search files inside git repo' })
    set('n', '<leader>fh', builtin.help_tags, { desc = 'Help command fuzzy finder' })
    set('n', '<leader>bb', builtin.builtin, { desc = 'Search option and plugin configuration' })
    set('n', '<leader>fd', builtin.diagnostics, { desc = 'Search for diagnostics' })
    set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
        winblend = 10,
        previewer = false,
      }))
    end, { desc = 'Search in current file' })

    set('n', '<leader>f/', function()
      builtin.live_grep({
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      })
    end, { desc = 'Search in open files' })

    vim.keymap.set('n', '<leader>fn', function()
      local opts = require('telescope.themes').get_dropdown({
        cwd = vim.fn.stdpath('config'),
      })
      builtin.find_files(opts)
    end, { desc = 'Search in neovim config' })
  end,
}
