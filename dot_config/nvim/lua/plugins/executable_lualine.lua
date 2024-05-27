return {
	-- See `:help lualine.txt`
	-- Set lualine as statusline
	"nvim-lualine/lualine.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("lualine").setup({})
	end,
}
