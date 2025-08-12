require("telescope").setup({

	extensions = {
		file_browser = {
			initial_mode = "normal",
			dir_icon = "",
			git_status = true,
			hijack_netrw = true,
		},
	},
})
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find git files" })
vim.keymap.set("n", "<leader>fs", function()
	builtin.grep_string({ search = vim.fn.input("Search > ") })
end, { desc = "Find string" })
