-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use({
        'nvim-telescope/telescope.nvim',
        tag = '0.1.4',
        -- or                            , branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    })

    use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })

    --    use({
    --        'projekt0n/github-nvim-theme',
    --        tag = 'v0.0.7',
    --        -- or                            branch = '0.0.x'
    --        config = function()
    --            require('github-theme').setup({
    --                -- ...
    --            })
    --        end
    --    })
    use('nvim-treesitter/playground')
    -- use('ourigen/skyline.vim')
    use { 'folke/tokyonight.nvim' }
    use { 'nvim-lualine/lualine.nvim' }
    use('tpope/vim-fugitive')
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },             -- Required
            { 'williamboman/mason.nvim' },           -- Optional
            { 'williamboman/mason-lspconfig.nvim' }, -- Optional

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },         -- Required
            { 'hrsh7th/cmp-nvim-lsp' },     -- Required
            { 'hrsh7th/cmp-buffer' },       -- Optional
            { 'hrsh7th/cmp-path' },         -- Optional
            { 'saadparwaiz1/cmp_luasnip' }, -- Optional
            { 'hrsh7th/cmp-nvim-lua' },     -- Optional

            -- Snippets
            { 'L3MON4D3/LuaSnip' },             -- Required
            { 'rafamadriz/friendly-snippets' }, -- Optional
        }
    }
    use {
        'mfussenegger/nvim-dap',
        requires = {
            { 'rcarriga/nvim-dap-ui' },
            { 'theHamsta/nvim-dap-virtual-text' },
            { 'nvim-telescope/telescope-dap.nvim' }
        }
    }
    use { 'norcalli/nvim-colorizer.lua' }
    -- copilot
    use { 'github/copilot.vim' }
    use { 'm4xshen/autoclose.nvim' }
    -- file explorer
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            { 'nvim-tree/nvim-web-devicons' }
        }
    }
    use { 'stevearc/conform.nvim' }

    use { 'sindrets/diffview.nvim' }

    use({
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
        ft = { "markdown" },
    })
end)
