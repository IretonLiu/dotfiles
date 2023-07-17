vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
require('tokyonight').setup({
    style = "night",
    transparent = "true",
})
vim.cmd [[colorscheme tokyonight]]
vim.cmd [[hi NvimTreeNormal guibg=none]]
