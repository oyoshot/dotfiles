return {
	{ "hrsh7th/cmp-nvim-lsp", lazy = true },
	{ "hrsh7th/cmp-nvim-lua", lazy = true },
	{ "hrsh7th/cmp-buffer", lazy = true },
	{ "hrsh7th/cmp-path", lazy = true },
	{ "hrsh7th/cmp-cmdline", lazy = true },
	{ "saadparwaiz1/cmp_luasnip", lazy = true },
	{ "onsails/lspkind.nvim", lazy = true },

	{
		"L3MON4D3/LuaSnip",
		build = "make install_jsregexp",
		lazy = true,
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		config = function()
			local lspkind = require("lspkind")
			local cmp = require("cmp")
			cmp.setup({
				sources = {
					{ name = "nvim_lsp" },
					{ name = "nvim_lua" },
					{ name = "luasnip" }, -- For luasnip users.
					-- { name = "orgmode" },
					{ name = "buffer" },
					{ name = "path" },
				},

				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),

				snippet = {
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},

				completion = {
					completeopt = "menu,menuone,preview,noselect",
				},

				formatting = {
					format = lspkind.cmp_format({}),
				},

				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},

				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
			})
		end,
	},
}
