return {
	"folke/snacks.nvim",
	keys = {
		{
			"<C-n>",
			function()
				Snacks.explorer()
			end,
			desc = "Toggle file explorer",
		},
	},
	opts = {
		explorer = {
			enabled = true,
			replace_netrw = false,
		},
		picker = {
			enabled = true,
			sources = {
				explorer = {
					hidden = true,
					ignored = true,
				},
			},
		},
	},
}
