require("telescope").setup({})

local builtin = require("telescope.builtin")

local function get_lsp_root()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	-- get root from first active client
	if clients and #clients > 0 then
		for _, client in ipairs(clients) do
			local root_dir = client.config.root_dir
			if root_dir then
				return root_dir
			end
		end
	end
	return vim.fn.getcwd() -- fallback
end

-- Custom function to find project root from LSP
vim.keymap.set("n", "<leader>ff", function()
	builtin.find_files({ cwd = get_lsp_root() })
end, { desc = "Find files from root" })

vim.keymap.set("n", "<leader>fg", function()
	builtin.live_grep({ cwd = get_lsp_root() })
end, { desc = "Live grep from root" })

vim.keymap.set("n", "<leader>fs", function()
	builtin.grep_string({ search = vim.fn.input("Search > "), cwd = get_lsp_root() })
end, { desc = "Find string" })
get_lsp_root()
