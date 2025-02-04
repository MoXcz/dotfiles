local set = vim.opt

-- Set leader key to <space>
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

set.number = true
set.relativenumber = true
-- Set to false if there is not a nerd font installed
vim.g.have_nerd_font = true
-- Enable mouse mode
set.mouse = 'a'

-- Change netrw style
-- vim.cmd("let g:netrw_liststyle = 3")

-- To share clipboard between nvim and system (not recommended, use xclip instead)
-- set.clipboard = "unnamedplus";

-- Use 2 spaces instead of tabs and respect indentation
set.tabstop = 2
set.softtabstop = 2
set.shiftwidth = 2
set.expandtab = true
set.autoindent = true
set.smartindent = true

-- For notes,it allows long lines of characters to be correctly displayed on screen
set.wrap = true
set.breakindent = true
set.linebreak = true

-- Avoid backups
set.swapfile = false
set.backup = false

-- Get access to long running undoes
set.undodir = os.getenv('HOME') .. '/.vim/undodir'
set.undofile = true

-- Disable dangling highlights
set.hlsearch = true
set.incsearch = true

-- Enable 24-bit RGB colors
set.termguicolors = true

-- The screen will move with 8 lines of space
set.scrolloff = 10

-- To see marks (errors, linting)
set.signcolumn = 'yes'
set.isfname:append('@-@')

-- Snappier markers update (decrease update time)
set.updatetime = 250

-- Decrease mapped sequence wait time
set.timeoutlen = 300

-- Turn the guide column at 80 characters
set.colorcolumn = '80'

-- To automatically start a new line after 80 characters
set.textwidth = 80

-- See difference between spaces, tabs and whitespaces
set.list = true
set.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live inside a split
set.inccommand = 'split'

set.cursorline = false

set.path:append('**')

set.spelllang = 'en_us'
set.spell = true

-- Deactivate default mode status
set.showmode = false

-- Case insensitive search unless it has one or more capital letters in the search term
set.ignorecase = true
set.smartcase = true

-- vim.api.nvim_create_autocommand('LspAttach', {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if not client then
--       vim.wo.foldmethod = 'expr'
--       vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
--     elseif client:supports_method('textDocument/foldingRange') then
--       vim.wo.foldmethod = 'expr'
--       vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
--     end
--   end,
-- })
