return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{ "<C-n>", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle file explorer" },
	},
	config = function()
		require("nvim-tree").setup({})
	end,
}
