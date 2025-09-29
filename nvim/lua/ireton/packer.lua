-- Only required if you have packer configured as `opt`
vim.cmd([[packadd packer.nvim]])

packer = require("packer")

return packer.startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		-- or                            , branch = '0.1.x',
		requires = { { "nvim-lua/plenary.nvim" } },
	})
	-- use {'nvim-telescope/telescope-media-files.nvim'}
	use({
		"nvim-telescope/telescope-file-browser.nvim",
		requires = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	})

	use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })

	use("nvim-treesitter/playground")

	-- use('ourigen/skyline.vim')
	use({ "folke/tokyonight.nvim" })
	use({ "nvim-lualine/lualine.nvim" })
	use({ "tpope/vim-fugitive" })

	-- LSP Support
	use({ "neovim/nvim-lspconfig" })
	use({ "williamboman/mason.nvim" }) -- Optional
	use({ "williamboman/mason-lspconfig.nvim" }) -- Optional

	-- Autocompletion
	use({ "hrsh7th/nvim-cmp" }) -- Required
	use({ "hrsh7th/cmp-nvim-lsp" }) -- Required
	use({ "hrsh7th/cmp-buffer" }) -- Optional
	use({ "hrsh7th/cmp-path" }) -- Optional
	use({ "hrsh7th/cmp-cmdline" }) -- optional
	use({ "saadparwaiz1/cmp_luasnip" }) -- Optional
	-- use { 'hrsh7th/cmp-nvim-lua' }     -- Optional

	-- Snippets
	use({
		"L3MON4D3/LuaSnip",
		requires = {
			{ "rafamadriz/friendly-snippets" }, -- Optional
		}, -- Required
	})
	use({
		"mfussenegger/nvim-dap",
		requires = {
			{ "nvim-neotest/nvim-nio" },
			{ "rcarriga/nvim-dap-ui" },
			{ "theHamsta/nvim-dap-virtual-text" },
			{ "nvim-telescope/telescope-dap.nvim" },
			{ "mfussenegger/nvim-dap-python" },
		},
	})
	use({ "norcalli/nvim-colorizer.lua" })
	-- -- copilot
	use({ "github/copilot.vim" })
	use({ "m4xshen/autoclose.nvim" })
	-- -- file explorer
	use({
		"stevearc/oil.nvim",
		requires = {
			"nvim-tree/nvim-web-devicons", -- optional, for file icons
		},
	})
	-- use {
	--     'nvim-tree/nvim-tree.lua',
	--     requires = {
	--         { 'nvim-tree/nvim-web-devicons' }
	--     }
	-- }

	-- Formatter
	use({ "stevearc/conform.nvim" })
	use({
		"ray-x/lsp_signature.nvim",
	})
	use({ "sindrets/diffview.nvim" })
	-- use({
	--     "iamcco/markdown-preview.nvim",
	--     run = function() vim.fn["mkdp#util#install"]() end,
	-- })
	-- use {
	--     "luukvbaal/nnn.nvim",
	-- }
end)
