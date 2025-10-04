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
	},
}
