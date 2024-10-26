return {
	"MeanderingProgrammer/markdown.nvim",
	lazy = true,
	ft = { "markdown" },
	name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
	config = function()
		require("render-markdown").setup({})
	end,
}
