return {
	-- OPTIONAL: for git status
	{ "lewis6991/gitsigns.nvim", lazy = true },
	-- OPTIONAL: for file icons
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	{
		"romgrk/barbar.nvim",
		--	event = "BufEnter",
		event = { "BufReadPre", "BufNewFile" },
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {
			-- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
			animation = true,
			-- insert_at_start = true,
			-- …etc.
		},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
}
