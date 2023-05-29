-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

local function custom_on_attach(bufnr)
    local api = require('nvim-tree.api')
    local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end
    api.config.mappings.default_on_attach(bufnr)

    -- Mapping for creating a file
    vim.keymap.set('n', '%', api.fs.create, opts('Create File'))
end
-- OR setup with some options
require("nvim-tree").setup({
    on_attach = custom_on_attach,
    sort_by = "case_sensitive",
    view = {
        width = 30,
    },
    renderer = {
        group_empty = true,
    },
    filters = {
        dotfiles = true,
    },
    actions = {
        open_file = {
            quit_on_open = true,
        }
    }
})
