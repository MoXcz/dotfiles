vim.lsp.enable({
  "lua_ls",
  "gopls",
  "rust_analyzer",
  "ols",
  "html",
  "cssls",
  "clangd",
  "ts_ls",
  "oxlint",
  "ty",
  "ruff",
  "svelte",
  "tailwindcss",
  "emmet_ls",
  "htmx",
  "templ",
  "bashls",
  "marksman",
  "expert",
  "phpactor",
})

vim.diagnostic.config({
  virtual_text = true, -- Show diagnostics inline
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
})
