return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- See `:help gitsigns.txt`
		signs = {
			add = { text = "┆" },
			change = { text = "┆" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
	},
}
