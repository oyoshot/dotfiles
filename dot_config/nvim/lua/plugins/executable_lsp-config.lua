return {
	-- Mason

	{ "williamboman/mason.nvim", lazy = true },
	{ "williamboman/mason-lspconfig.nvim", lazy = true },

	-- null-ls

	{ "jay-babu/mason-null-ls.nvim", lazy = true },
	{ "nvimtools/none-ls.nvim", lazy = true },

	-- LSP

	{
		"neovim/nvim-lspconfig",
		lazy = true,
		event = { "CursorHold", "CursorHoldI" },
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		init = function()
			-- Reserve a space in the gutter
			-- This will avoid an annoying layout shift in the screen
			vim.opt.signcolumn = "yes"
		end,
		config = function()
			-- Add cmp_nvim_lsp capabilities settings to lspconfig
			-- This should be executed before you configure any language server
			local lsp_defaults = require("lspconfig").util.default_config
			lsp_defaults.capabilities =
				vim.tbl_deep_extend("force", lsp_defaults.capabilities, require("cmp_nvim_lsp").default_capabilities())

			vim.lsp.inlay_hint.enable(true)

			local lsp_format_on_save = function(bufnr)
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({
							async = true,
							filter = function(c)
								local disabled_format_clients = { "lua_ls" }
								return not vim.tbl_contains(disabled_format_clients, c.name)
							end,
						})
					end,
				})
			end

			-- LspAttach is where you enable features that only work
			-- if there is a language server active in the file
			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP actions",
				callback = function(event)
					-- local opts = { buffer = event.buf }
					-- vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
					-- vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
					-- vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
					-- vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
					-- vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
					-- vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
					-- vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
					-- vim.keymap.set("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
					-- vim.keymap.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
					-- vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)

					vim.g.markdown_fenced_language = {
						"ts=typescript",
					}
					lsp_format_on_save(bufnr)
				end,
			})

			-- NOTE: It's important that you set up the plugins in the following order:
			-- 1. mason.nvim
			-- 2. mason-lspconfig.nvim
			-- 3. Setup servers via lspconfig

			require("mason").setup({})

			require("mason-lspconfig").setup({
				ensure_installed = {
					--"gopls",
					"marksman",
					"lua_ls",
					"terraformls",
					"tflint",
					-- "tsserver",
					"yamlls",
					--"dagger",
					-- "rust_analyzer",
					"jdtls",
					"clangd",
					"solargraph",
					"bashls",
					"ruff",
					"pyright",
					--"pylsp",
					"typos_lsp",
					"denols",
					--"vtsls",
				},
				handlers = {
					-- this first function is the "default handler"
					-- it applies to every language server without a "custom handler"
					function(server_name)
						if server_name == "denols" then
							return
						end
						-- require("lspconfig")[server_name].setup({})
					end,
				},
			})

			local lspconfig = require("lspconfig")

			lspconfig.lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			})

			-- (Optional) Configure lua language server for neovim
			lspconfig.gopls.setup({
				on_attach = function(_, _)
					print("hello gopls")
					vim.api.nvim_create_autocmd("BufWritePre", {
						pattern = "*.go",
						callback = function()
							vim.lsp.buf.code_action({
								context = { only = { "source.organizeImports" } },
								apply = true,
							})
						end,
					})
				end,
			})

			require("lspconfig").ruff.setup({
				init_options = {
					settings = {
						configuration = "--config=~/.config/ruff/pyproject.toml",
					},
				},
			})

			lspconfig.pyright.setup({
				settings = {
					pyright = {
						-- Using Ruff's import organizer
						disableOrganizeImports = true,
					},
					python = {
						analysis = {
							-- Ignore all files for analysis to exclusively use Ruff for linting
							ignore = { "*" },
						},
					},
				},
			})

			lspconfig.typos_lsp.setup({
				init_options = {
					config = vim.fn.expand("~/.config/typos/typos.toml"),
				},
			})

			local async = require("plenary.async")
			local root_finder = require("utils.root_finder")

			async.run(function()
				local cwd = vim.fn.getcwd()

				local deno_root_task = root_finder.async_find_root({ "deno.json", "deno.jsonc" }, cwd, 5)
				local node_root_task = root_finder.async_find_root({ "package.json", "tsconfig.json" }, cwd, 5)

				local deno_root = deno_root_task()
				local node_root = node_root_task()

				if deno_root then
					lspconfig.denols.setup({})
					return -- `typescript-tools` のセットアップはスキップ
				end

				if node_root then
					require("typescript-tools").setup({
						settings = {
							tsserver_file_preferences = {
								includeInlayParameterNameHints = "all",
							},
						},
					})
				end
			end)

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

			--NOTE: Sources found installed in mason will automatically be setup for null-ls.
			-- See mason-null-ls.nvim's documentation for more details:
			-- https://github.com/jay-babu/mason-null-ls.nvim#setup

			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.diagnostics.fish,
					null_ls.builtins.formatting.fish_indent,
					null_ls.builtins.formatting.prettierd.with({
						filetypes = {
							-- "javascript",
							-- "javascriptreact",
							-- "typescript",
							-- "typescriptreact",
							"vue",
							"css",
							"scss",
							"less",
							"html",
							"json",
							"jsonc",
							"yaml",
							"markdown",
							"markdown.mdx",
							"graphql",
							"handlebars",
							"svelte",
							"astro",
							"htmlangular",
						},
					}),
					-- null_ls.builtins.formatting.shfmt.with({
					--     filetypes = { "sh", "zsh" },
					-- }),
					null_ls.builtins.diagnostics.textlint,
					null_ls.builtins.diagnostics.tfsec,
				},
			})

			local mason_null_ls = require("mason-null-ls")
			mason_null_ls.setup({
				ensure_installed = {
					"hadolint",
					"terraform_fmt",
					"terraform_validate",
					"stylua",
					--"gofumpt",
					"golangci_lint",
					--"isort",
				},
				--automatic_installation = true,
				automatic_installation = { exclude = { "textlint" } },
				handlers = {},
			})
		end,
	},
}
