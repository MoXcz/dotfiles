-- mason ships typescript-svelte-plugin inside svelte-language-server, so no per-project install is needed
local svelte_plugin = vim.fn.stdpath("data")
    .. "/mason/packages/svelte-language-server/node_modules/typescript-svelte-plugin"

return {
  init_options = {
    plugins = {
      { name = "typescript-svelte-plugin", location = svelte_plugin },
    },
  },
}
