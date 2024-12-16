return {
  "tpope/vim-fugitive",
  lazy = false,
  config = function()
    vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
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

        -- Git pull set to rebase
        vim.keymap.set("n", "<leader>P", function()
          vim.cmd.Git({ "pull", "--rebase" })
        end, opts)

        -- Set the branch to push (when the branch is not set correctly, the keymaps above will not work)
        vim.keymap.set("n", "<leader>tt", ":Git push -u origin ", opts)
      end,
    })

    vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")
    vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")
  end,
}
