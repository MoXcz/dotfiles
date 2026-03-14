require("mason").setup({})
require("mason-tool-installer").setup({
  ensure_installed = {
    -- LSPs
    "lua-language-server",
    "rust-analyzer",
    "html-lsp",
    "emmet-ls",
    "typescript-language-server",
    "gopls",
    "templ",
    "pyright",
    "ols",
    'htmx-lsp',
    "tailwindcss-language-server",
    "bash-language-server",
    "clangd",
    "expert",
    "css-lsp",
    "marksman",
    "shellcheck",
    -- formatters
    "prettier",
    "google-java-format",
    "black",
    "codelldb",
    "goimports",
    "impl",
    "gomodifytags",
    "golangci-lint",
    "delve",
    "shfmt",
    "pretty-php",
    "phpactor",
  },
})

require("mason-lspconfig").setup {
  automatic_enable = false
}
