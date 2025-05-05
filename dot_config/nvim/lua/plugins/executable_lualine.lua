return {
	-- See `:help lualine.txt`
	-- Set lualine as statusline
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"lewis6991/gitsigns.nvim",
	},
	lazy = true,
	event = { "BufReadPost", "BufAdd", "BufNewFile" },
	config = function()
		local custom_catppuccin = require("lualine.themes.catppuccin")
		local function diff_source()
			local gitsigns = vim.b.gitsigns_status_dict
			if gitsigns then
				return {
					added = gitsigns.added,
					modified = gitsigns.changed,
					removed = gitsigns.removed,
				}
			end
		end
		require("lualine").setup({
			options = {
				theme = custom_catppuccin,
			},
			sections = {
				lualine_b = { { "diff", source = diff_source } },
			},
		})
	end,
}
