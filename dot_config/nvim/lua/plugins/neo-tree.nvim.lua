return {
	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		{ "3rd/image.nvim", opts = {} }, -- Optional image support in preview window: See `# Preview Mode` for more information
	},
	lazy = true, -- neo-tree will lazily load itself
	keys = {
		{ "<C-n>", "<CMD>Neotree toggle<CR>", desc = "Toggle file explorer" },
	},
	---@module "neo-tree"
	---@type neotree.Config?
	opts = {
		default_component_configs = {
			git_status = {
				symbols = {
					-- Change type
					added = "✚",
					modified = "",
				},
			},
		},
		filesystem = {
			filtered_items = {
				--visible = true,
				hide_dotfiles = false,
				hide_gitignored = true,
				never_show = { ".git" },
			},
		},
	},
}
