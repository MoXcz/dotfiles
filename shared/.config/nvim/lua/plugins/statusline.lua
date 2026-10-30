local function modes()
  local flags = {}
  if vim.g.disable_autoformat or vim.b.disable_autoformat then table.insert(flags, "no-fmt") end
  if vim.g.blink_manual then table.insert(flags, "manual-cmp") end
  return table.concat(flags, " ")
end

require("lualine").setup({
  options = {
    icons_enabled = true,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    always_divide_middle = true,
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      "branch",
      {
        "diff",
        source = function()
          local status = vim.b.gitsigns_status_dict
          if status then
            return { added = status.added, modified = status.changed, removed = status.removed }
          end
        end,
      },
      "diagnostics",
    },
    lualine_c = {
      { "filename", path = 1, symbols = { modified = " ●", readonly = " " } },
    },
    lualine_x = {
      { modes, color = "WarningMsg" },
      "lsp_status",
      { "encoding",   cond = function() return vim.bo.fileencoding ~= "utf-8" end },
      { "fileformat", cond = function() return vim.bo.fileformat ~= "unix" end },
      "filetype",
    },
    lualine_z = { "location" },
  },
  extensions = { "oil", "fugitive", "quickfix", "man" },
})
