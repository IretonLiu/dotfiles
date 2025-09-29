vim.lsp.config("luals", {
	cmd = { "lua-language-server" },
	-- Filetypes to automatically attach to.
	filetypes = { "lua" },
	root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git", "init.lua" },
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
		},
	},
})
