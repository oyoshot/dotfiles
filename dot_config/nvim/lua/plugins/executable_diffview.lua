return {
	"sindrets/diffview.nvim",
	lazy = true,
	cmd = { "DiffviewOpen" },
	opts = {
		default_args = {
			DiffviewOpen = { "--imply-local" },
		},
	},
}
