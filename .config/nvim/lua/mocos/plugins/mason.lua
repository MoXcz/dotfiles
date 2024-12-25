return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'olrtg/nvim-emmet',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
  },
  config = function()
    -- Emmet abbreviations
    vim.keymap.set({ 'n', 'v' }, '<leader>xe', require('nvim-emmet').wrap_with_abbreviation)
    -- Enable mason
    local mason = require('mason')
    local mason_lspconfig = require('mason-lspconfig')
    mason.setup({})
    mason_lspconfig.setup({
      ensure_installed = { 'lua_ls', 'rust_analyzer', 'html' },
    })
    require('mason-tool-installer').setup({
      ensure_installed = { 'prettier', 'google-java-format', 'black', 'clangd', 'marksman', 'codelldb' },
    })
  end,
}
