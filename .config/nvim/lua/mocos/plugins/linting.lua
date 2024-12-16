return {
  'mfussenegger/nvim-lint',
  -- Linting only happens when a new buffer is read or created
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')

    lint.linters_by_ft = {
      --      javascript = { 'eslint_d' },
      --      typescript = { 'eslint_d' },
      --      javascriptreact = { 'eslint_d' },
      --      typescriptreact = { 'eslint_d' },
      --      svelte = { 'eslint_d' },
      --      python = { 'pylint' },
    }

    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

    -- An autocommand that attaches the linter to the buffer every time a new buffer is created
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- Manually activate linter
    vim.keymap.set('n', '<leader>l', function()
      lint.try_lint()
    end, { desc = 'Trigger linting for current file' })
  end,
}
