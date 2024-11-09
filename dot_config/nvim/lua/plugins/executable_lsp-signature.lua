return {
	"ray-x/lsp_signature.nvim",
	lazy = true,
	event = "LspAttach",
	config = function(_, _)
		require("lsp_signature").setup({
			bind = true,
			handler_opts = {
				border = "rounded",
			},
		})
	end,
}
