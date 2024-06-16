return {
	-- Autocompletion
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	{
		"hrsh7th/nvim-cmp",
		lazy = true,
		event = "InsertEnter",
		dependencies = {
			{ "hrsh7th/cmp-path" },
			{ "L3MON4D3/LuaSnip" },
		},
		config = function()
			-- Here is where you configure the autocompletion settings.
			-- The arguments for .extend() have the same shape as `manage_nvim_cmp`:
			-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v2.x/doc/md/api-reference.md#manage_nvim_cmp

			require("lsp-zero.cmp").extend()

			-- And you can configure cmp even more, if you want to.
			local cmp = require("cmp")
			local cmp_action = require("lsp-zero.cmp").action()

			cmp.setup({
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = {
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-f>"] = cmp_action.luasnip_jump_forward(),
					["<C-b>"] = cmp_action.luasnip_jump_backward(),
				},
				completion = {
					completeopt = "menu,menuone,preview,noselect",
				},
				formatting = {
					fields = { "abbr", "kind", "menu" },
				},
			})

			-- If you want insert `(` after select function or method item
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	-- LSP
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		event = { "BufReadPre", "BufNewFile" },
		lazy = true,
		opts = {
			{
				float_border = "rounded",
				call_servers = "local",
				configure_diagnostics = true,
				setup_servers_on_start = true,
				set_lsp_keymaps = {
					preserve_mappings = false,
					omit = {},
				},
				manage_nvim_cmp = {
					set_sources = "recommended",
					set_basic_mappings = true,
					set_extra_mappings = false,
					use_luasnip = true,
					set_format = true,
					documentation_window = true,
				},
			},
		},
		config = function(_, opts)
			-- This is where you modify the settings for lsp-zero
			-- Note: autocompletion settings will not take effect
			require("lsp-zero.settings").preset(opts)
		end,
	},

	{
		"neovim/nvim-lspconfig",
		cmd = "LspInfo",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
		},
		config = function()
			-- This is where all the LSP shenanigans will live

			local lsp_zero = require("lsp-zero")
			lsp_zero.set_sign_icons({
				error = "✘",
				warn = "▲",
				hint = "⚑",
				info = "»",
			})

			local lsp_format_on_save = function(bufnr)
				local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })
				vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = augroup,
					callback = function()
						vim.lsp.buf.format({
							async = true,
							timeout_ms = 10000,
							filter = function(c)
								local disabled_format_clients = { "lua_ls", "tsserver" }
								return not vim.tbl_contains(disabled_format_clients, c.name)
							end,
						})
					end,
				})
			end

			lsp_zero.preset("recommended")

			lsp_zero.on_attach(function(client, bufnr)
				-- see :help lsp-zero-keybindings
				-- to learn the available actions
				lsp_zero.default_keymaps({ buffer = bufnr })
				vim.keymap.set("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")
				vim.keymap.set("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>")
				lsp_format_on_save(bufnr)
			end)

			vim.g.markdown_fenced_language = {
				"ts=typescript",
			}
			vim.lsp.inlay_hint.enable(true)
			lsp_zero.setup()
		end,
	},

	-- Mason
	{
		"williamboman/mason.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason").setup({})
		end,
		optional = true,
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "codelldb" })
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = "williamboman/mason.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lsp_zero = require("lsp-zero")
			require("mason-lspconfig").setup({
				ensure_installed = {
					"gopls",
					"marksman",
					"lua_ls",
					"terraformls",
					"tflint",
					"tsserver",
					"yamlls",
					"dagger",
					-- "rust_analyzer",
					"jdtls",
					"clangd",
					"solargraph",
					"bashls",
					"ruff_lsp",
					"pyright",
					"typos_lsp",
					"denols",
				},
				handlers = {
					lsp_zero.default_setup,
				},
			})

			local lspconfig = require("lspconfig")

			lspconfig.lua_ls.setup({
				settings = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			})

			-- (Optional) Configure lua language server for neovim
			lspconfig.gopls.setup({
				on_attach = function(client, bufnr)
					print("hello gopls")
					vim.api.nvim_create_autocmd("BufWritePre", {
						pattern = "*.go",
						callback = function()
							vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
						end,
					})
				end,
			})

			lspconfig.pyright.setup({
				settings = {
					pyright = {
						-- Using Ruff's import organizer
						disableOrganizeImports = true,
					},
				},
			})

			lspconfig.ruff_lsp.setup({
				init_options = {
					settings = {
						format = {
							args = {},
						},
						lint = {
							args = {},
						},
					},
				},
			})

			lspconfig.typos_lsp.setup({
				init_options = {
					config = vim.fn.expand("~/.config/typos/typos.toml"),
				},
			})

			local function custom_attach(client, bufnr)
				local active_clients = vim.lsp.get_active_clients()
				if client.name == "denols" then
					for _, other_client in ipairs(active_clients) do
						if other_client.name == "tsserver" then
							other_client.stop()
						end
					end
				elseif client.name == "tsserver" then
					for _, other_client in ipairs(active_clients) do
						if other_client.name == "denols" then
							client.stop()
						end
					end
				end
			end

			lspconfig.tsserver.setup({
				root_dir = function(fname)
					local deno_root = lspconfig.util.root_pattern("deno.json", "deno.jsonc")(fname)
					if deno_root then
						return nil
					end
					return lspconfig.util.root_pattern("package.json", "tsconfig.json", ".git")(fname)
				end,
				on_attach = custom_attach,
				single_file_support = false,
			})

			lspconfig.denols.setup({
				root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
				on_attach = custom_attach,
			})

			lspconfig.terraformls.setup({
				on_attach = function(_, _)
					vim.env.PATH = "/usr/bin:" .. vim.env.PATH
				end,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sh", "zsh" },
				callback = function()
					vim.lsp.start({
						name = "bash-language-server",
						cmd = { "bash-language-server", "start" },
					})
					-- 頑張って shfmt するかもしれない
				end,
			})
		end,
	},

	{
		"jay-babu/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "williamboman/mason.nvim", "nvimtools/none-ls.nvim" },
		config = function()
			-- See mason-null-ls.nvim's documentation for more details:
			-- https://github.com/jay-babu/mason-null-ls.nvim#setup
			require("mason-null-ls").setup({
				ensure_installed = {
					"hadolint",
					"terraform_fmt",
					"terraform_validate",
					"stylua",
					"gofumpt",
					"golangci_lint",
					-- "prettierd",
				},
				automatic_installation = true,
				handlers = {},
			})
		end,
	},

	{
		"nvimtools/none-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.diagnostics.fish,
					null_ls.builtins.formatting.fish_indent,
					-- null_ls.builtins.formatting.shfmt.with({
					--     filetypes = { "sh", "zsh" },
					-- }),
				},
			})
		end,
	},
}
