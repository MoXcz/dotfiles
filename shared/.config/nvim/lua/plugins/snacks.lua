local Snacks = require("snacks")
require("todo-comments").setup({})

Snacks.setup({
  bigfile = { enabled = true },
  animate = { enabled = false },
  notifier = { enabled = true, timeout = 3000 },
  notify = { enabled = true },
  quickfile = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  styles = { notification = { wo = { wrap = true } } },
  toggle = { enabled = true },
  input = { enabled = true },
  indent = { enabled = true },
  picker = { enabled = true, hidden = true },
  explorer = { enabled = true },
  rename = { enabled = true },
  gitbrowse = { enabled = true },
  git = { enabled = true },
  bufdelete = { enabled = true },
  zen = { enabled = false },
  dashboard = { enabled = false },
})

Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle
    .option("conceallevel",
      { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" })
    :map("<leader>uc")
Snacks.toggle
    .option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" })
    :map("<leader>uA")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.inlay_hints():map('<leader>uh')
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.dim():map("<leader>uD")
Snacks.toggle.animate():map("<leader>ua")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.scroll():map("<leader>uS")
Snacks.toggle.profiler():map("<leader>dpp")
Snacks.toggle.profiler_highlights():map("<leader>dph")
Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
Snacks.toggle.zen():map("<leader>uz")

local keymaps = {
  -- Scratch
  { '<leader>R',   function() Snacks.rename.rename_file() end,                                            desc = 'Rename File', },
  { '<leader>un',  function() Snacks.notifier.hide() end,                                                 desc = 'Dismiss All Notifications', },
  { ']]',          function() Snacks.words.jump(vim.v.count1) end,                                        desc = 'Next Reference',               mode = { 'n', 't' }, },
  { '[[',          function() Snacks.words.jump(-vim.v.count1) end,                                       desc = 'Prev Reference',               mode = { 'n', 't' }, },
  -- Pickers
  { "<leader>ff",  function() Snacks.picker.files({ action = "replace" }) end,                            desc = "Find Files" },
  { "<leader>fs",  function() Snacks.picker.grep() end,                                                   desc = "Grep" },
  { "<leader>fg",  function() Snacks.picker.grep_word() end,                                              desc = "Visual selection or word",     mode = { "n", "x" } },
  { "<leader>fp",  function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end,                desc = "Find Config File" },
  { "<leader>fd",  function() Snacks.picker.diagnostics() end,                                            desc = "Diagnostics" },
  { "<leader>fh",  function() Snacks.picker.help() end,                                                   desc = "Help Pages" },
  { "<leader>fc",  function() Snacks.picker.colorschemes() end,                                           desc = "Colorschemes" },
  { "<leader>fm",  function() Snacks.picker.man() end,                                                    desc = "Man Pages" },
  { "<leader>fk",  function() Snacks.picker.keymaps() end,                                                desc = "Keymaps" },
  { "<leader>fi",  function() Snacks.picker.icons() end,                                                  desc = "Icons" },
  { "<leader>fq",  function() Snacks.picker.qflist() end,                                                 desc = "Quickfix List" },
  { "<leader>ft",  function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
  --  Symbols are things like variables, functions, types, etc.
  { "<leader>fS",  function() Snacks.picker.lsp_symbols() end,                                            desc = "LSP Symbols" },
  { "<leader>fw",  function() Snacks.picker.lsp_workspace_symbols() end,                                  desc = "LSP Workspace Symbols" },
  -- git
  { "<leader>gb",  function() Snacks.picker.git_branches() end,                                           desc = "Git Branches" },
  { "<leader>gl",  function() Snacks.picker.git_log() end,                                                desc = "Git Log" },
  { "<leader>gL",  function() Snacks.picker.git_log_line() end,                                           desc = "Git Log Line" },
  { "<leader>gf",  function() Snacks.picker.git_log_file() end,                                           desc = "Git Log File" },
  { "<leader>gc",  function() Snacks.picker.git_status() end,                                             desc = "Git Status" },
  { "<leader>gd",  function() Snacks.picker.git_diff() end,                                               desc = "Git Diff (Hunks)" },
  { "<leader>gS",  function() Snacks.picker.git_stash() end,                                              desc = "Git Stash" },
  { '<leader>gB',  function() Snacks.gitbrowse() end,                                                     desc = 'Git Browse', },
  -- gh
  { "<leader>gi",  function() Snacks.picker.gh_issue() end,                                               desc = "GitHub Issues (open)" },
  { "<leader>gI",  function() Snacks.picker.gh_issue({ state = "all" }) end,                              desc = "GitHub Issues (all)" },
  { "<leader>gp",  function() Snacks.picker.gh_pr() end,                                                  desc = "GitHub Pull Requests (open)" },
  { "<leader>gP",  function() Snacks.picker.gh_pr({ state = "all" }) end,                                 desc = "GitHub Pull Requests (all)" },
  -- Lazygit
  { '<leader>lgf', function() Snacks.lazygit.log_file() end,                                              desc = 'Lazygit Current File History', },
  { '<leader>lgg', function() Snacks.lazygit() end,                                                       desc = 'Lazygit', },
  { '<leader>lgl', function() Snacks.lazygit.log() end,                                                   desc = 'Lazygit Log (cwd)', },
  -- LSP
  { "gd",          function() Snacks.picker.lsp_definitions() end,                                        desc = "Goto Definition" },
  { "gD",          function() Snacks.picker.lsp_declarations() end,                                       desc = "Goto Declaration" },
  { "grr",         function() Snacks.picker.lsp_references() end,                                         desc = "References" },
  { "gri",         function() Snacks.picker.lsp_implementations() end,                                    desc = "Goto Implementation" },
  { "gt",          function() Snacks.picker.lsp_type_definitions() end,                                   desc = "Goto T[y]pe Definition" },
  {
    "gv",
    function()
      local params = vim.lsp.util.make_position_params()
      vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx)
        if err or not result or vim.tbl_isempty(result) then
          vim.notify("No definition found", vim.log.levels.WARN)
          return
        end
        vim.cmd("vsplit")
        vim.lsp.util.show_document(result[1], "utf-8", { focus = true })
      end)
    end,
    desc = "Goto Definition in Vertical Split"
  },
  -- Top Pickers & Explorer
  { "<leader>sf", function() Snacks.picker.smart() end,              desc = "Smart Find Files" },
  { "<leader>,",  function() Snacks.picker.buffers() end,            desc = "Buffers" },
  { "<leader>:",  function() Snacks.picker.command_history() end,    desc = "Command History" },
  { "<leader>e",  function() Snacks.explorer() end,                  desc = "File Explorer" },
  { '<leader>fn', function() Snacks.notifier.show_history() end,     desc = 'Notification History', },
  -- search
  { '<leader>s"', function() Snacks.picker.registers() end,          desc = "Registers" },
  { '<leader>s/', function() Snacks.picker.search_history() end,     desc = "Search History" },
  { "<leader>sa", function() Snacks.picker.autocmds() end,           desc = "Autocmds" },
  { "<leader>sC", function() Snacks.picker.commands() end,           desc = "Commands" },
  { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
  { "<leader>sH", function() Snacks.picker.highlights() end,         desc = "Highlights" },
  { "<leader>sj", function() Snacks.picker.jumps() end,              desc = "Jumps" },
  { "<leader>sl", function() Snacks.picker.loclist() end,            desc = "Location List" },
  { "<leader>sm", function() Snacks.picker.marks() end,              desc = "Marks" },
  { "<leader>sp", function() Snacks.picker.lazy() end,               desc = "Search for Plugin Spec" },
  { "<leader>sR", function() Snacks.picker.resume() end,             desc = "Resume" },
  { "<leader>z",  function() Snacks.zen() end,                       desc = "Toggle Zen Mode" },
  { "<leader>Z",  function() Snacks.zen.zoom() end,                  desc = "Toggle Zoom" },
  n_esc = { "<esc>", { "cmp_close", "cancel" }, mode = "n", expr = true },
  i_esc = { "<esc>", { "cmp_close", "stopinsert" }, mode = "i", expr = true },
  i_cr = { "<cr>", { "cmp_accept", "confirm" }, mode = "i", expr = true },
  i_tab = { "<tab>", { "cmp_select_next", "cmp" }, mode = "i", expr = true },
  i_ctrl_w = { "<c-w>", "<c-s-w>", mode = "i", expr = true },
  i_up = { "<up>", { "hist_up" }, mode = { "i", "n" } },
  i_down = { "<down>", { "hist_down" }, mode = { "i", "n" } },
  q = "cancel",
}

for _, map in ipairs(keymaps) do
  local opts = { desc = map.desc }
  if map.silent ~= nil then
    opts.silent = map.silent
  end
  if map.noremap ~= nil then
    opts.noremap = map.noremap
  else
    opts.noremap = true
  end
  if map.expr ~= nil then
    opts.expr = map.expr
  end

  local mode = map.mode or "n"
  vim.keymap.set(mode, map[1], map[2], opts)
end
