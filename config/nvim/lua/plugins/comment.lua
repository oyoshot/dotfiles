return {
	"numToStr/Comment.nvim",
	event = { "CursorHold", "CursorHoldI" },
	config = function()
		require("Comment").setup()
	end,
}
