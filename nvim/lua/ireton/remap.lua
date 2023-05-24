vim.g.mapleader = " "
vim.keymap.set("n", "<leader>fe", vim.cmd.NvimTreeToggle, { desc = "Toggle NvimTree" })


-- move visual mode selected blocks
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected block down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected block up" })

vim.keymap.set("n", "J", "mzJ`z") -- keep cursor when appending next line
-- keep cursor centred
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
-- keep search term centred
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

--copying and pasting
---- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over selected text without yanking it" })

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Copy to clipboard" })

vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d", { desc = "Delete without yanking" })

vim.keymap.set("i", "C-c", "<Esc>", { desc = "Exit insert mode" })

-- lsp
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open diagnostics" })
