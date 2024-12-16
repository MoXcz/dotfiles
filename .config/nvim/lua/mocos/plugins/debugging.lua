return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
  },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')

    require('dapui').setup()
    require('mason').setup()
    require('mason-nvim-dap').setup({
      handlers = {},
      ensure_installed = { 'codelldb' },
    })

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    local set = vim.keymap.set

    set('n', '<Leader>db', dap.toggle_breakpoint, {})
    set('n', '<Leader>dc', dap.continue, {})
    set('n', '<Leader>di', dap.step_into, {})
    set('n', '<Leader>do', dap.step_over, {})
    set('n', '<Leader>dk', dap.step_out, {})
    --set("n", "<Leader>dd", dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")), {})
    set('n', '<Leader>de', dap.terminate, {})
    set('n', '<Leader>dr', dap.run_last, {})

    -- rustaceanvim
    set('n', '<Leader>dt', "<cmd>lua vim.cmd('RustLsp testables')<CR>", { desc = 'Debugger testables' })
  end,
}
