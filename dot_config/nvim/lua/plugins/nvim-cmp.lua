return {
	{ "hrsh7th/cmp-nvim-lsp", lazy = true },
	{ "hrsh7th/cmp-nvim-lua", lazy = true },
	{ "hrsh7th/cmp-buffer", lazy = true },
	{ "hrsh7th/cmp-path", lazy = true },
	{ "hrsh7th/cmp-cmdline", lazy = true },
	{ "f3fora/cmp-spell", lazy = true },
	{ "lukas-reineke/cmp-under-comparator", lazy = true },
	{ "andersevenrud/cmp-tmux", lazy = true },
	{ "saadparwaiz1/cmp_luasnip", lazy = true },
	{ "kdheepak/cmp-latex-symbols", lazy = true },
	{ "ray-x/cmp-treesitter", lazy = true },
	{ "onsails/lspkind.nvim", lazy = true },

	{
		"L3MON4D3/LuaSnip",
		build = "make install_jsregexp",
		lazy = true,
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			local snippet_path = vim.fn.stdpath("config") .. "/snips/"
			if not vim.tbl_contains(vim.opt.rtp:get(), snippet_path) then
				vim.opt.rtp:append(snippet_path)
			end

			require("luasnip").config.set_config()
			require("luasnip.loaders.from_lua").lazy_load()
			require("luasnip.loaders.from_vscode").lazy_load()
			require("luasnip.loaders.from_snipmate").lazy_load()
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		lazy = true,
		event = "InsertEnter",
		config = function()
			local border = function(hl)
				return {
					{ "┌", hl },
					{ "─", hl },
					{ "┐", hl },
					{ "│", hl },
					{ "┘", hl },
					{ "─", hl },
					{ "└", hl },
					{ "│", hl },
				}
			end

			local lspkind = require("lspkind")
			local cmp = require("cmp")
			cmp.setup({
				preselect = cmp.PreselectMode.None,

				window = {
					completion = cmp.config.window.bordered({
						scrollbar = false,
					}),
					documentation = {
						border = border("CmpDocBorder"),
						winhighlight = "Normal:CmpDoc",
					},
				},

				sorting = {
					priority_weight = 2,
				},

				formatting = {
					fields = { "abbr", "kind", "menu" },
					format = lspkind.cmp_format({}),
				},

				matching = {
					disallow_partial_fuzzy_matching = false,
				},

				performance = {
					async_budget = 1,
					max_view_entries = 120,
				},

				-- You can set mappings if you want

				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-w>"] = cmp.mapping.abort(),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						elseif require("luasnip").expand_or_locally_jumpable() then
							require("luasnip").expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
						elseif require("luasnip").jumpable(-1) then
							require("luasnip").jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),

					["<CR>"] = cmp.mapping({
						i = function(fallback)
							if cmp.visible() and cmp.get_active_entry() then
								cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = false })
							else
								fallback()
							end
						end,
						s = cmp.mapping.confirm({ select = true }),
						--c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true }),
					}),
				}),

				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},

				-- You should specify your *installed* sources.
				sources = {
					{ name = "nvim_lsp", max_item_count = 350 },
					{ name = "nvim_lua" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "treesitter" },
					{ name = "spell" },
					{ name = "tmux" },
					{ name = "orgmode" },
					{
						name = "buffer",
						option = {
							get_bufnrs = function()
								return vim.api.nvim_buf_line_count(0) < 7500 and vim.api.nvim_list_bufs() or {}
							end,
						},
					},
					{ name = "latex_symbols" },
					--{ name = "copilot" },
					-- { name = "codeium" },
					-- { name = "cmp_tabnine" },
				},

				experimental = {
					ghost_text = {
						hl_group = "Whitespace",
					},
				},
			})
		end,
	},
}
