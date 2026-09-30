return {
	"MeanderingProgrammer/markdown.nvim",
	event = { "BufReadPre", "BufNewFile" },
	name = "render-markdown", -- Only needed if you have another plugin named markdown.nvim
	config = function()
		require("render-markdown").setup({})
	end,
}
