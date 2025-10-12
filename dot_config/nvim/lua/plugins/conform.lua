local function is_deno(ctx)
	local util = require("conform.util")
	return util.root_file({ "deno.json", "deno.jsonc" })(ctx)
end

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			json = { "prettierd", "prettier" },
			yaml = { "prettierd", "prettier" },
			markdown = { "prettierd", "prettier" },
			zsh = { "shfmt" },
		},
		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			return { lsp_fallback = true, timeout_ms = 500 }
		end,
		formatters = {
			prettierd = {
				condition = function(ctx)
					return not is_deno(ctx)
				end,
			},
			prettier = {
				condition = function(ctx)
					return not is_deno(ctx)
				end,
			},
		},
	},
}
