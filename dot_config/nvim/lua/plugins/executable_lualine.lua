return {
	-- See `:help lualine.txt`
	-- Set lualine as statusline
	"nvim-lualine/lualine.nvim",
	lazy = true,
	event = { "BufReadPost", "BufAdd", "BufNewFile" },
	config = function()
		local custom_catppuccin = require("lualine.themes.catppuccin")
		require("lualine").setup({
			options = {
				theme = custom_catppuccin,
			},
		})
	end,
	dependencies = {
		"lewis6991/gitsigns.nvim",
	},
}
