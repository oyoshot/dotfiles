return {
	"shortcuts/no-neck-pain.nvim",
	version = "*",
	cond = false,
	event = { "BufReadPost", "BufAdd", "BufNewFile" },
	config = function()
		vim.cmd("NoNeckPain")
	end,
}
