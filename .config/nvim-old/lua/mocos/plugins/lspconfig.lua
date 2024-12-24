return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    -- Useful status updates for LSP.
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { 'j-hui/fidget.nvim', opts = {} },
    -- Allows extra capabilities provided by nvim-cmp
    'hrsh7th/cmp-nvim-lsp',
    { 'antosha417/nvim-lsp-file-operations', config = true },
    {
      -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          -- Load luvit types when the `vim.uv` word is found
          { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        },
      },
    },
    { 'Bilal2453/luvit-meta', lazy = true },
    {
      'mrcjkb/rustaceanvim',
      version = '^5', -- Recommended
      lazy = false, -- This plugin is already lazy
      ft = 'rust',
      config = function()
        local mason_registry = require('mason-registry')
        local codelldb = mason_registry.get_package('codelldb')
        local extension_path = codelldb:get_install_path() .. '/extension/'
        local codelldb_path = extension_path .. 'adapter/codelldb'
        local liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
        local cfg = require('rustaceanvim.config')

        vim.g.rustaceanvim = {
          dap = {
            adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
          },
        }
      end,
    },
    {
      'saecki/crates.nvim',
      ft = 'toml',
      tag = 'stable',
      config = function()
        require('crates').setup({
          completion = {
            cmp = {
              enabled = true,
            },
          },
        })
      end,
    },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = '' })
        end

        map('gd', require('telescope.builtin').lsp_definitions, 'goto to definition')
        map('gD', vim.lsp.buf.declaration, 'goto declaration')
        map('grr', require('telescope.builtin').lsp_references, 'goto references')
        map('gi', require('telescope.builtin').lsp_implementations, 'goto implementation')
        map('<leader>gt', require('telescope.builtin').lsp_type_definitions, 'goto type definition')
        --  Symbols are things like variables, functions, types, etc.
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, 'document symbols')
        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'workspace symbols')
        -- Rename the variable under your cursor.
        map('grn', vim.lsp.buf.rename, 'rename')
        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
        --
        map('n', '<leader>D', '<cmd>Telescope diagnostics bufnr=0<CR>', '')
        map('n', '<leader>dl', vim.diagnostic.open_float, '')
        map('n', '[d', vim.diagnostic.goto_prev, '')
        map('n', ']d', vim.diagnostic.goto_next, '')
        map('n', 'K', vim.lsp.buf.hover, '')
        map('n', '<leader>rs', ':LspRestart<CR>', '')
        map('n', '<leader>rd', ':LspStop<CR>', '')

        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup('lsp_highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('lsp_detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = 'lsp_highlight', buffer = event2.buf })
            end,
          })
        end

        -- vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), { opts })
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
    local servers = {
      clangd = {},
      gopls = {},
      pyright = {},
      rust_analyzer = {},
      ts_ls = {},
      bashls = {},
      html = {},
      cssls = {},
      prettier = {},
      eslint_d = {},
      emmet_ls = {},
      black = {},
      --[[
      prismals = {},
      isort = {},
      pylint = {},
      ]]
      lua_ls = {
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = {},
        settings = {
          lua = {
            completion = {
              callsnippet = 'replace',
            },
            diagnostics = { disable = { 'missing-fields' }, globals = { 'vim' } },
          },
        },
      },
    }

    require('mason').setup({})
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua',
    })
    require('mason-tool-installer').setup({ ensure_installed = ensure_installed })
    require('mason-lspconfig').setup({
      handlers = {
        ['rust_analyzer'] = function() end,
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    })
  end,
}
