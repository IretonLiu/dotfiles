require("ireton")
vim.lsp.enable('luals')
vim.lsp.enable('ruff')
vim.lsp.enable('pylsp')


vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
        vim.keymap.set('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
        vim.keymap.set('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>')
    end,
})
