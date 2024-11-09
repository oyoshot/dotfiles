return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	cond = false,
	lazy = true,
	keys = {
		{ "<C-n>", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle file explorer" },
	},
	opts = {},
}
