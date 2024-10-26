return {
	"VidocqH/lsp-lens.nvim",
	lazy = true,
	event = "LspAttach",
	config = function()
		require("lsp-lens").setup({})
	end,
}
