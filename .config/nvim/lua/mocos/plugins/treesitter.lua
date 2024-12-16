return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs',
  opts = {
    ensure_installed = {
      'vimdoc',
      'javascript',
      'typescript',
      'c',
      'lua',
      'rust',
      'jsdoc',
      'bash',
      'cpp',
      'html',
      'css',
      'bash',
      'luadoc',
      'markdown_inline',
      'diff',
    },
    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = { 'markdown', 'ruby' },
      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,
    },
    indent = { enable = true, disable = { 'ruby' } },
  },
  config = function()
    local treesitter_parser_config = require('nvim-treesitter.parsers').get_parser_configs()
    treesitter_parser_config.templ = {
      install_info = {
        url = 'https://github.com/vrischmann/tree-sitter-templ.git',
        files = { 'src/parser.c', 'src/scanner.c' },
        branch = 'master',
      },
    }

    vim.treesitter.language.register('templ', 'templ')
  end,
}
