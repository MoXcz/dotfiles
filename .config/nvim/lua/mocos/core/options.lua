vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.number = true
vim.opt.relativenumber = true
-- Set to false if there is not a nerd font installed
vim.g.have_nerd_font = true
-- Enable mouse mode
vim.opt.mouse = 'a'

-- Change netrw style
-- vim.cmd("let g:netrw_liststyle = 3")

-- To share clipboard between nvim and system (not recommended, use xclip instead)
-- vim.opt.clipboard = "unnamedplus";

-- Use 2 spaces instead of tabs and respect indentation
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- For notes,it allows long lines of characters to be corerctly displayed on screen
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true

-- Avoid backups
vim.opt.swapfile = false
vim.opt.backup = false

-- Get access to long running undoes
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

-- Disable dangling highlights
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Enable 24-bit RGB colors
vim.opt.termguicolors = true

-- The screen will move with 8 lines of space
vim.opt.scrolloff = 8

-- To see marks (errors, linting)
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append('@-@')

-- Snappier markers update
vim.opt.updatetime = 50

-- Turn the guide column at 80 characters
vim.opt.colorcolumn = '80'

-- For obsidian/markdown syntax
vim.opt_local.conceallevel = 2

-- To automatically start a new line after 80 characters
vim.opt.textwidth = 80

-- See difference between spaces, tabs and whitespaces
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live inside a split
vim.opt.inccommand = 'split'

vim.opt.cursorline = false

vim.opt.path:append('**')

vim.opt.spelllang = 'en_us'
vim.opt.spell = true

-- Deactivate default mode status
vim.opt.showmode = false
