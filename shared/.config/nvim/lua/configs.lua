vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.signcolumn = "yes:1"
opt.numberwidth = 2
opt.termguicolors = true
opt.ignorecase = true
opt.swapfile = false
opt.backup = false
opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.shiftround = true -- round to multiple of 'shiftwidth
opt.list = true       -- Show whitespace characters
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", eol = "󰌑" }
opt.number = true
opt.relativenumber = true
opt.wrap = false
opt.cursorline = true
opt.scrolloff = 10
opt.sidescrolloff = 10
opt.inccommand = "split"
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true
opt.completeopt = { "menuone", "popup", "noinsert" }
opt.winborder = "rounded"
opt.hlsearch = false
opt.incsearch = true
opt.showmode = false

local map = vim.keymap.set

-- Move between splits using vim motions
map("n", "<C-j>", "<C-w><C-j>")
map("n", "<C-k>", "<C-w><C-k>")
map("n", "<C-l>", "<C-w><C-l>")
map("n", "<C-h>", "<C-w><C-h>")

-- center cursor after jump and search
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map('n', 'n', 'nzzzv')
map('n', 'N', 'Nzzzv')

-- cd into current file dir
map("n", "<leader>cd", '<cmd>lua vim.fn.chdir(vim.fn.expand("%:p:h"))<CR>')

-- Move highlighted text
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Sets cursor in the middle when half-page jumping and in search terms
-- map('n', '<C-d>', '<C-d>zz')
-- map('n', '<C-u>', '<C-u>zz')
-- map('n', 'n', 'nzzzv')
-- map('n', 'N', 'Nzzzv')

-- yank to system clipboard
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "yank to system clipboard" })

-- Replace current word in all file
map("n", "<leader>ss", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- Creates executable file
map("n", "<leader>xc", "<cmd>!chmod +x %<CR>", { silent = true })
-- Create new tmux session using script to fuzzy find directory
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer.sh<CR>")
map("n", "Q", "<nop>")
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>ps", '<cmd>lua vim.pack.update()<CR>')

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
autocmd("TextYankPost", {
  group = augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.cmd.filetype("plugin indent on")
