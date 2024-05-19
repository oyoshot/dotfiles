return {
	keys = {
		{ "<C-n>", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle file explorer" },
		{
			"n",
			"<leader>ef",
			"<cmd>NvimTreeFindFileToggle<CR>",
			desc = "Toggle file explorer on current file",
		},
		{ "n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", desc = "Collapse file explorer" },
		{ "n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", desc = "Refresh file explorer" },
	},
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local nvimtree = require("nvim-tree")

		-- configure nvim-tree
		nvimtree.setup({
			view = {
				width = 35,
				relativenumber = false,
			},
			-- change folder arrow icons
			renderer = {
				indent_markers = {
					enable = false,
				},
			},
			-- disable window_picker for
			-- explorer to work well with
			-- window splits
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			filters = {
				custom = { ".DS_Store" },
			},
			git = {
				ignore = false,
			},
		})
	end,
}
