return {
  "vim-test/vim-test",
  dependencies = { "preservim/vimux" },
  config = function()
    vim.keymap.set("n", "<leader>tT", ":TestFile<CR>")
    vim.keymap.set("n", "<leader>tt", ":TestNearest<CR>")
    vim.cmd("let test#strategy = 'neovim'")
  end
}
