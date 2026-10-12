-- .config/nvim/after/lua/lsp/html.lua
return {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html", "templ", "template" },
  settings = {
    html = {
      format = {
        wrapLineLength = 0,
        wrapAttributes = "auto",
      },
    },
  },
  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
}
