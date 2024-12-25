-- To avoid redundancy
local set = vim.keymap.set

vim.g.mapleader = ' '
-- Directory listing : changed to oil.nvim
-- set("n", "<leader>pd", vim.cmd.Ex)

set('v', '<leader>x', ':.lua<CR>', { desc = 'Execute highlighted' })
set('n', '<leader>x', ':.lua<CR>', { desc = 'Execute the current line' })
set('n', '<leader><leader>x', '<cmd>source %<CR>', { desc = 'Source the current file' })

-- Move between splits using vim motions
set('n', '<c-j>', '<c-w><c-j>')
set('n', '<c-k>', '<c-w><c-k>')
set('n', '<c-l>', '<c-w><c-l>')
set('n', '<c-h>', '<c-w><c-h>')

-- Move highlighted text
set('v', 'J', ":m '>+1<CR>gv=gv")
set('v', 'K', ":m '<-2<CR>gv=gv")

-- Avoid weird J spacing
set('n', 'J', 'mzJ`z')

-- Sets cursor in the middle when half-page jumping and in search terms
set('n', '<C-d>', '<C-d>zz')
set('n', '<C-u>', '<C-u>zz')
set('n', 'n', 'nzzzv')
set('n', 'N', 'Nzzzv')

-- Buffer will not hold the deleted item
set('x', '<leader>p', [["_dP]])
set({ 'n', 'v' }, '<leader>dd', [["_d]])

-- Yanking will be saved to system clipboard
set({ 'n', 'v' }, '<leader>y', [["+y]])
set('n', '<leader>Y', [["+Y]])

-- Open new tmux session to another project
set('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer<CR>')

-- Format code : Changed to Conform
-- vim.keymap.set("n", "<leader>af", vim.lsp.buf.format)

-- Replace current word in all file
set('n', '<leader>ss', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Creates executable file
set('n', '<leader>xc', '<cmd>!chmod +x %<CR>', { silent = true })

-- Create new tmux session using script to fuzzy find directory
set('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer<CR>')

-- To split windows
set('n', '<leader>sv', '<C-w>v', { desc = 'Split window vertically' })
set('n', '<leader>sh', '<C-w>s', { desc = 'Split window horizontally' })
set('n', '<leader>se', '<C-w>=', { desc = 'Make splits equal size' })
set('n', '<leader>sx', '<cmd>close<CR>', { desc = 'Close current split' })

-- To create new tabs
set('n', '<leader>to', '<cmd>tabnew<CR>', { desc = 'Open new tab' })
set('n', '<leader>tx', '<cmd>tabclose<CR>', { desc = 'Close current tab' })
set('n', '<leader>tn', '<cmd>tabn<CR>', { desc = 'Go to next tab' })
set('n', '<leader>tp', '<cmd>tabp<CR>', { desc = 'Go to previous tab' })
set('n', '<leader>tf', '<cmd>tabnew %<CR>', { desc = 'Open current buffer in new tab' })

-- To control the size of splits (width/height)
set('n', '<M-,>', '<c-w>5<')
set('n', '<M-.>', '<c-w>5>')
set('n', '<M-t>', '<C-W>+')
set('n', '<M-s>', '<C-W>-')

set('n', 'Q', '<nop>')

-- Navigate quickfix list
set('n', '<M-j>', '<cmd>cnext<CR>')
set('n', '<M-k>', '<cmd>cprev<CR>')
set('n', '<M-h>', '<cmd>copen<CR>') -- Open quickfix list

-- Set local settings for terminal buffers
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.scrolloff = 0

    vim.bo.filetype = 'terminal'
  end,
})

-- Exit terminal mode
set('t', '<esc>', '<c-\\><c-n>')

local job_id = 0
-- Open a terminal at the bottom of the screen with a fixed height.
set('n', ',st', function()
  vim.cmd.new()
  vim.cmd.wincmd('J')
  vim.api.nvim_win_set_height(0, 12)
  vim.wo.winfixheight = true
  vim.cmd.term()

  job_id = vim.bo.channel
end)

set('n', '<space>cr', function()
  vim.fn.chansend(job_id, { 'cargo run\r\n' })
end)

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
