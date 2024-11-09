return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependency = {
		"nvim-lua/plenary.nvim",
		-- not strictly required, but recommended
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
		-- Optional image support in preview window: See `# Preview Mode` for more information
		"3rd/image.nvim",
	},
	lazy = true,
	keys = {
		{ "<C-n>", "<CMD>Neotree toggle<CR>", desc = "Toggle file explorer" },
	},
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
