return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	cond = false,
	lazy = true,
	event = { "BufReadPost", "BufAdd", "BufNewFile" },
	config = function()
		vim.cmd("NoNeckPain")
	end,
}
