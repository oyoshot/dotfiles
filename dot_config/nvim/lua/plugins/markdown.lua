return {
	"MeanderingProgrammer/markdown.nvim",
	ft = { "markdown" },
	name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
	config = function()
		require("render-markdown").setup({})
	end,
}
