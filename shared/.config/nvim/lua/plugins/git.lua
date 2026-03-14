local m_fugitive = vim.api.nvim_create_augroup("m_fugitive", {})

local autocmd = vim.api.nvim_create_autocmd
autocmd("BufWinEnter", {
  group = m_fugitive,
  pattern = "*",
  callback = function()
    if vim.bo.ft ~= "fugitive" then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local opts = { buffer = bufnr, remap = false }
    vim.keymap.set("n", "<leader>p", function()
      vim.cmd.Git("push")
    end, opts)

    vim.keymap.set("n", "<leader>P", function()
      vim.cmd.Git({ "pull", "--rebase" })
    end, opts)

    vim.keymap.set("n", "<leader>tt", ":Git push -u origin ", opts)
  end,
})

vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")
vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")
vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit!<CR>", { desc = "Split current buffer changes (current branch)" })
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

require("gitsigns").setup({
  current_line_blame = true,
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  signs_staged = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
  },
  on_attach = function(buffer)
    local gs = package.loaded.gitsigns

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
    end

    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, "Next Hunk")

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, "Prev Hunk")

    map("n", "]C", function()
      gs.nav_hunk("last")
    end, "Last Hunk")
    map("n", "[C", function()
      gs.nav_hunk("first")
    end, "First Hunk")

    map("n", "<leader>hd", gs.diffthis, "Diff This")
    map("n", "<leader>hD", function()
      gs.diffthis("~")
    end, "Diff This ~")
  end,
})
