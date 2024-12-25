return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'saghen/blink.cmp',
      {
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          },
        },
      },
    },
    config = function()
      local lspconfig = require('lspconfig')
      local mason_lspconfig = require('mason-lspconfig')
      -- local cmp_nvim_lsp = require("cmp_nvim_lsp")
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function()
          local key = vim.keymap.set
          key('n', '<leader>rd', ':LspStop<CR>')
          key('n', 'gd', require('telescope.builtin').lsp_definitions)
          key('n', 'gD', vim.lsp.buf.declaration)
          key('n', 'grr', require('telescope.builtin').lsp_references)
          key('n', 'gi', require('telescope.builtin').lsp_implementations)
          key('n', '<leader>gt', require('telescope.builtin').lsp_type_definitions)
          --  Symbols are things like variables, functions, types, etc.
          key('n', '<leader>ds', require('telescope.builtin').lsp_document_symbols)
          key('n', '<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols)
          -- Rename the variable under your cursor.
          key('n', 'grn', vim.lsp.buf.rename)
          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          key({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action)
          key('n', '<leader>D', '<cmd>Telescope diagnostics bufnr=0<CR>')
          key('n', '<leader>dl', vim.diagnostic.open_float)
          key('n', '[d', vim.diagnostic.goto_prev)
          key('n', ']d', vim.diagnostic.goto_next)
          key('n', 'K', vim.lsp.buf.hover)
          key('n', '<leader>rs', ':LspRestart<CR>')
          key('n', '<leader>rd', ':LspStop<CR>')
        end,
      })

      local capabilities = require('blink.cmp').get_lsp_capabilities()
      mason_lspconfig.setup_handlers({
        function(server)
          lspconfig[server].setup({
            capabilities = capabilities,
          })
        end,
        ['emmet_ls'] = function()
          lspconfig['emmet_ls'].setup({
            capabilities = capabilities,
            filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less', 'svelte' },
          })
        end,
        ['rust_analyzer'] = function() end,
      })
    end,
  },
}
