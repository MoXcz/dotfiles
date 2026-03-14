vim.pack.add({
  "https://github.com/rebelot/kanagawa.nvim",
  "https://github.com/mbbill/undotree",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  "https://github.com/folke/snacks.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/tpope/vim-fugitive",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/christoomey/vim-tmux-navigator",
  "https://github.com/jake-stewart/multicursor.nvim",
})

vim.cmd.colorscheme("kanagawa-dragon")

local map = vim.keymap.set
map("n", "<leader>fu", vim.cmd.UndotreeToggle, { desc = "Undo history" })

require("plugins.mason")
require("plugins.lsp")
require("plugins.snacks")
require("plugins.blink")
require("plugins.oil")
require("plugins.treesitter")
require("plugins.conform")
require("plugins.git")
require("plugins.statusline")
require("plugins.multicursors")
