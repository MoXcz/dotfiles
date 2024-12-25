return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup({})
    -- Add a buffer
    vim.keymap.set('n', '<leader>ad', function()
      harpoon:list():add()
    end)
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)
    -- Set <space>1...<space>5 to move between buffers
    for _, idx in ipairs({ 1, 2, 3, 4, 5 }) do
      vim.keymap.set('n', string.format('<space>%d', idx), function()
        harpoon:list():select(idx)
      end)
    end
  end,
}
