return {
	"neovim/nvim-lspconfig",
	event = "BufReadPre",
	config = function()
		vim.lsp.config("*", {
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
		})
		vim.lsp.inlay_hint.enable(true)

		local lsp_format_on_save = function(bufnr)
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({
						async = true,
						filter = function(c)
							local disabled_format_clients = { "lua_ls", "vtsls" }
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
				vim.g.markdown_fenced_language = {
					"ts=typescript",
				}
				lsp_format_on_save(event.buf)
			end,
		})

		pcall(require, "lspconfig")

		local cfg = vim.fn.stdpath("config")
		local globs = {
			cfg .. "/lua/lsp/*.lua",
			cfg .. "/lsp/*.lua",
		}

		local files = {}

		for _, pat in ipairs(globs) do
			for _, f in ipairs(vim.fn.glob(vim.fs.normalize(pat), true, true)) do
				table.insert(files, f)
			end
		end

		local names = vim.iter(files)
			:map(function(p)
				return p:match("([^/]+)%.lua$")
			end)
			:filter(function(n)
				return n and n ~= "init"
			end)
			:totable()

		pcall(function()
			local common = require("lsp.common")
			if type(common) == "table" then
				vim.lsp.config("*", common)
			end
		end)

		if #names > 0 and vim.lsp.enable then
			local ok = pcall(vim.lsp.enable, names) -- 0.11 は配列OK
			if not ok then
				for _, n in ipairs(names) do
					pcall(vim.lsp.enable, n)
				end
			end
		end

		local function is_deno_project(bufnr)
			return vim.fs.root(bufnr or 0, { "deno.json", "deno.jsonc" }) ~= nil
		end

		vim.api.nvim_create_autocmd({ "LspAttach", "BufEnter" }, {
			desc = "In Deno projects, only denols may live",
			callback = function(ev)
				local bufnr = ev and ev.buf or 0
				if not is_deno_project(bufnr) then
					return
				end

				-- stop any non-deno LSP attached to this buffer
				for _, c in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
					if c.name ~= "denols" then
						c.stop(true)
					end
				end
			end,
		})
	end,
}
