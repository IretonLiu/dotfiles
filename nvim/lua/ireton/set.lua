vim.opt.relativenumber = true
vim.opt.nu = true
vim.opt.numberwidth = 4
vim.opt.wrap = false
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = false


vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

-- netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- autoformat
vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
-- vim.opt.colorcolumn = "100"

-- debugging
vim.keymap.set("n", "<F5>", ":lua require'dap'.continue()<CR>")
vim.keymap.set("n", "<F10>", ":lua require'dap'.step_over()<CR>")
vim.keymap.set("n", "<F11>", ":lua require'dap'.step_into()<CR>")
vim.keymap.set("n", "<F12>", ":lua require'dap'.step_out()<CR>")
vim.keymap.set("n", "<leader>b", ":lua require'dap'.toggle_breakpoint()<CR>")
vim.keymap.set("n", "<leader>B", ":lua require'dap'.continue()<CR>")
vim.keymap.set("n", "<leader>lp", ":lua require'dap'.continue()<CR>")
vim.keymap.set("n", "<leader>dr", ":lua require'dap'.continue()<CR>")

-- lsp logging
vim.lsp.set_log_level("warn")

-- copilot
vim.g.copilot_assume_mapped = true
