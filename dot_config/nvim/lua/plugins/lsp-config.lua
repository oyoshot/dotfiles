return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		vim.lsp.config("*", {
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
		})
		vim.lsp.inlay_hint.enable(true)

		-- LspAttach is where you enable features that only work
		-- if there is a language server active in the file
		vim.api.nvim_create_autocmd("LspAttach", {
			desc = "LSP actions",
			callback = function()
				vim.g.markdown_fenced_language = {
					"ts=typescript",
				}
				-- Note: format-on-save is handled by conform.nvim
			end,
		})

		pcall(require, "lspconfig")

		local cfg = vim.fn.stdpath("config")
		local globs = {
			cfg .. "/lua/lsp/*.lua",
			cfg .. "/lsp/*.lua",
			cfg .. "/after/lsp/*.lua",
		}

		local names = {}

		for _, pat in ipairs(globs) do
			for _, f in ipairs(vim.fn.glob(vim.fs.normalize(pat), true, true)) do
				local name = f:match("([^/]+)%.lua$")
				if name and name ~= "init" then
					names[name] = true
				end
			end
		end

		pcall(function()
			local common = require("lsp.common")
			if type(common) == "table" then
				vim.lsp.config("*", common)
			end
		end)

		for name in vim.spairs(names) do
			local ok, err = pcall(vim.lsp.enable, name)
			if not ok then
				vim.notify(("Failed to enable LSP %s: %s"):format(name, err), vim.log.levels.ERROR)
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
