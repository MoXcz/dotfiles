return {
  'stevearc/conform.nvim',
  event = { 'BufReadPre' },
  cmd = { 'ConformInfo' },
  config = function()
    local conform = require('conform')
    conform.setup({
      formatters_by_ft = {
        lua = { 'stylua' },
        go = { 'goimports', 'gofmt' },
        python = { 'isort', 'black' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescriptreact = { 'prettier' },
        svelte = { 'prettier' },
        css = { 'prettier' },
        html = { 'prettier' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        graphql = { 'prettier' },
        liquid = { 'prettier' },
        cpp = { 'clangd' },
        java = { 'google-java-format' },

        -- "_" run formatters on filetypes that don't have other formatters configured.
        ['_'] = { 'trim_whitespace' },
      },
      -- If this is set, Conform will run the formatter on save.
      format_on_save = {
        lsp_format = 'fallback',
        timeout_ms = 1000,
        async = false,
      },
      notify_on_error = true,
      notify_no_formatters = true,
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>af', function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = 'Format file or range' })
  end,
}
