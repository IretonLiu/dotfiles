local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("ruff", {
	cmd = { "ruff", "server" },
	capabilities = capabilities,
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
	init_options = {
		settings = {
			lineLength = 100,
		},
	},
})
