return {
	"ray-x/lsp_signature.nvim",
	lazy = true,
	event = "LspAttach",
	opts = {
		bind = true,
		handler_opts = {
			border = "rounded",
		},
	},
	config = function(_, opts)
		require("lsp_signature").setup(opts)
	end,
}
