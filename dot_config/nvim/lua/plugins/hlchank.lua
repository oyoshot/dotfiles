return {
	"shellRaining/hlchunk.nvim",
	lazy = true,
	event = { "CursorHold", "CursorHoldI" },
	config = function()
		require("hlchunk").setup({
			chunk = {
				enable = true,
				style = "#00ffff",
			},
			indent = {
				enable = true,
			},
			line_num = {
				enable = true,
				style = "#00ffff",
			},
		})
	end,
}
