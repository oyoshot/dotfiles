return {
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
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

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		lazy = true,
		event = "InsertEnter",
		dependencies = {
			{ "L3MON4D3/LuaSnip" },
			{ "hrsh7th/cmp-path" },
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
		"neovim/nvim-lspconfig",
		cmd = "LspInfo",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },

			-- null-ls
			{ "nvimtools/none-ls.nvim" },
			{ "jay-babu/mason-null-ls.nvim" },

			-- rustaceanvim
			{
				{ "simrat39/rust-tools.nvim", enable = false },
				{
					"mrcjkb/rustaceanvim",
					version = "^3", -- Recommended
					dependencies = {
						"nvim-lua/plenary.nvim",
						"mfussenegger/nvim-dap",
						{
							"lvimuser/lsp-inlayhints.nvim",
							opts = {},
						},
					},
					ft = { "rust" },
					opts = {
						server = {
							on_attach = function(client, bufnr)
								-- register which-key mappings
								local wk = require("which-key")
								wk.register({
									["<leader>cR"] = {
										function()
											vim.cmd.RustLsp("codeAction")
										end,
										"Code Action",
									},
									["<leader>dr"] = {
										function()
											vim.cmd.RustLsp("debuggables")
										end,
										"Rust debuggables",
									},
								}, { mode = "n", buffer = bufnr })
							end,
							settings = {
								-- rust-analyzer language server configuration
								["rust-analyzer"] = {
									cargo = {
										allFeatures = true,
										loadOutDirsFromCheck = true,
										runBuildScripts = true,
									},
									-- Add clippy lints for Rust.
									checkOnSave = {
										allFeatures = true,
										command = "clippy",
										extraArgs = { "--no-deps" },
									},
									procMacro = {
										enable = true,
										ignored = {
											["async-trait"] = { "async_trait" },
											["napi-derive"] = { "napi" },
											["async-recursion"] = { "async_recursion" },
										},
									},
								},
							},
						},
					},
					config = function(_, opts)
						vim.g.rustaceanvim = vim.tbl_deep_extend("force", {}, {
							inlay_hints = {
								highlight = "NonText",
							},
							tools = {
								hover_actions = {
									auto_focus = true,
								},
							},
							server = {
								on_attach = function(client, bufnr)
									require("lsp-inlayhints").on_attach(client, bufnr)
								end,
							},
						})
					end,
				},
			},
		},
		config = function()
			-- This is where all the LSP shenanigans will live

			local lsp_zero = require("lsp-zero")
			require("mason").setup({})
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
					--"ruff_lsp",
					"pyright",
				},
				handlers = {
					lsp_zero.default_setup,
				},
			})

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

			-- (Optional) Configure lua language server for neovim
			require("lspconfig").gopls.setup({
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

			require("lspconfig").pyright.setup({
				-- on_attach = on_attach,
				-- settings = {
				-- 	pyright = {
				-- 		-- Using Ruff's import organizer
				-- 		disableOrganizeImports = true,
				-- 	},
				-- },
			})

			-- require("lspconfig").ruff_lsp.setup({
			-- 	init_options = {
			-- 		settings = {
			-- 			format = {
			-- 				args = {},
			-- 			},
			-- 			lint = {
			-- 				args = {},
			-- 			},
			-- 		},
			-- 	},
			-- 	on_attach = function(client, bufnr)
			-- 		if client.name == "ruff_lsp" then
			-- 			-- Disable hover in favor of Pyright
			-- 			client.server_capabilities.hoverProvider = false
			-- 		end
			-- 	end,
			-- })

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sh", "zsh", "template" },
				callback = function()
					vim.lsp.start({
						name = "bash-language-server",
						cmd = { "bash-language-server", "start" },
					})
					-- 頑張って shfmt するかもしれない
				end,
			})

			lsp_zero.setup()

			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					-- Replace these with the tools you have installed
					-- make sure the source name is supported by null-ls
					-- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
					null_ls.builtins.diagnostics.cspell.with({
						method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
						diagnostics_postprocess = function(diagnostic)
							-- レベルをWARNに変更（デフォルトはERROR）
							diagnostic.severity = vim.diagnostic.severity["WARN"]
						end,
						-- 起動時に設定ファイル読み込み
						extra_args = { "--config", "~/.config/cspell/cspell.json" },
					}),
					null_ls.builtins.diagnostics.ruff.with({
						extra_args = { "--config", vim.fn.expand("~/.config/ruff/pyproject.toml") },
					}),
					null_ls.builtins.formatting.ruff.with({
						extra_args = { "--config", vim.fn.expand("~/.config/ruff/pyproject.toml") },
					}),
				},
			})

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
					"prettierd",
				},
				automatic_installation = true,
				handlers = {},
			})
		end,
	},
}
