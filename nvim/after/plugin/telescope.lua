require("telescope").setup({})
local builtin = require("telescope.builtin")

-- Custom function to find project root from LSP
local function project_root_telescope()
	local clients = vim.lsp.get_active_clients({ bufnr = 0 })
	local root = nil

	for _, client in pairs(clients) do
		-- language specific root_dir handling
		if client.name == "basedpyright" and client.config.root_dir then
			root = client.config.root_dir
			break
		end
	end

	if root then
		builtin.find_files({ cwd = root })
	else
		builtin.find_files() -- fallback to current dir
	end
end

vim.keymap.set("n", "<leader>ff", project_root_telescope, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find git files" })
vim.keymap.set("n", "<leader>fs", function()
	builtin.grep_string({ search = vim.fn.input("Search > ") })
end, { desc = "Find string" })
