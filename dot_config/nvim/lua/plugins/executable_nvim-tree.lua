return {
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		keys = {
			{ "<C-n>", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle file explorer" },
		},
		opts = {},
	},
}
