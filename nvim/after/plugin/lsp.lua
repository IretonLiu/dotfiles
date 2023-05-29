-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local lsp = require('lsp-zero')
lsp.preset('recommended')

-- (Optional) Configure lua language server for neovim
lsp.nvim_workspace()
local cmp = require('cmp')
local cmp_mappings = lsp.defaults.cmp_mappings({
        ["<C-Space>"] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
})

-- disable cmp tab keybindings for copilot
cmp_mappings['<Tab>'] = vim.NIL
cmp_mappings['<S-Tab>'] = vim.NIL

lsp.setup_nvim_cmp({
    mapping = cmp_mappings
})

-- (Optional) Configure clangd for neovim
-- Remove multiple different client offset_encodings warning
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.offsetEncoding = { "utf-8" }
require('lspconfig').clangd.setup({
    capabilities = capabilities
})


lsp.setup()


vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = false,
    underline = true,
    severity_sort = false,
    float = true,
})
