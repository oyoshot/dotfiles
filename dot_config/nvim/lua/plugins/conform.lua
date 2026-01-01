local deno_cache = {}

local function cache_key(dir)
	return (vim.uv and vim.uv.fs_realpath(dir)) or dir
end

local function is_deno_project(bufnr)
	if vim.bo[bufnr].buftype ~= "" then
		return false
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return false
	end

	local dir = vim.fs.dirname(name)
	if not dir then
		return false
	end

	local key = cache_key(dir)
	if deno_cache[key] ~= nil then
		return deno_cache[key]
	end

	local found = vim.fs.find({ "deno.json", "deno.jsonc" }, { path = dir, upward = true })[1]
	local ok = found ~= nil
	deno_cache[key] = ok
	return ok
end

local function prettier_chain()
	return { "prettierd", stop_after_first = true }
end

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = { "deno.json", "deno.jsonc" },
	callback = function()
		deno_cache = {}
	end,
})

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },

			markdown = function(bufnr)
				if is_deno_project(bufnr) then
					return { "deno_fmt" }
				end
				return prettier_chain()
			end,

			json = function(bufnr)
				if is_deno_project(bufnr) then
					return { "deno_fmt" }
				end
				return prettier_chain()
			end,

			yaml = prettier_chain(),
			zsh = { "shfmt" },
		},

		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			return { lsp_format = "fallback", timeout_ms = 500 }
		end,
	},
}
