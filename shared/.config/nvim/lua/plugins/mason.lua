require("mason").setup({})
require("mason-tool-installer").setup({
  ensure_installed = {
    -- LSPs
    "lua-language-server",
    "rust-analyzer",
    "html-lsp",
    "svelte-language-server",
    "emmet-ls",
    "typescript-language-server",
    "gopls",
    "templ",
    "ty",
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
    "goimports",
    "golangci-lint",
    "shfmt",
    "pretty-php",
    "phpactor",
    "ruff",
    "stylua",
    "taplo",
    "clang-format",
    "oxfmt",
    "jq",
  },
})

require("mason-lspconfig").setup {
  automatic_enable = false
}
