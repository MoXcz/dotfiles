require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports", "gofmt", stop_after_first = true },
		python = { "ruff_format", "black", stop_after_first = true },
		markdown = { "prettier" },
		javascript = { "biome", "prettier", stop_after_first = true },
		typescript = { "biome", "prettier", stop_after_first = true },
		javascriptreact = { "biome", "prettier", stop_after_first = true },
		typescriptreact = { "biome", "prettier", stop_after_first = true },
		css = { "prettier" },
		toml = { "taplo" },
		svelte = { "prettier" },
		html = { lsp_format_opt = "prefer" },
		yaml = { "prettier" },
		graphql = { "prettier" },
		liquid = { "prettier" },
		java = { "google-java-format" },
		c = { "clang-format" },
		json = { "jq" },
		jsonc = { "jq" },
		rust = { "rustfmt" },
		elixir = { lsp_format = "prefer" },
		odin = { "odinfmt" },
		elm = { "elm_format" },
		php = { "pretty-php" },
		bash = { "shfmt" },
		sh = { "shfmt" },

		-- "_" run formatters on filetypes that don't have other formatters configured.
		["_"] = { "trim_whitespace" },
	},
	formatters = {
		biome = { require_cwd = true },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 500, lsp_format = "fallback" }
	end,
})

vim.api.nvim_create_user_command("FormatDisable", function(opts)
	if opts.bang then
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
	vim.notify("Autoformat disabled" .. (opts.bang and " (buffer)" or " (global)"), vim.log.levels.WARN)
end, { desc = "Disable autoformat-on-save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
	vim.notify("Autoformat enabled", vim.log.levels.INFO)
end, { desc = "Re-enable autoformat-on-save" })

local auto_format = true

vim.keymap.set("n", "<leader>uf", function()
	auto_format = not auto_format
	if auto_format then
		vim.cmd("FormatEnable")
	else
		vim.cmd("FormatDisable")
	end
end, { desc = "Toggle Autoformat" })

vim.keymap.set({ "n", "v" }, "<leader>af", function()
	require("conform").format({ async = true }, function(err, did_edit)
		if not err and did_edit then
			vim.notify("Code formatted", vim.log.levels.INFO, { title = "Conform" })
		end
	end)
end, { desc = "Format buffer" })

vim.keymap.set({ "n", "v" }, "<leader>aF", function()
	require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
end, { desc = "Format Injected Langs" })
