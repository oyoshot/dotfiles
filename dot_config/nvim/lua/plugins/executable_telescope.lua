return {
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
	{
		"prochri/telescope-all-recent.nvim",
		lazy = true,
		opts = {},
	},
	{ "kkharji/sqlite.lua", lazy = true },

	--{
	--	"danielfalk/smart-open.nvim",
	--	cond = false,
	--	branch = "0.2.x",
	--	config = function()
	--		require("telescope").load_extension("smart_open")
	--	end,
	--},

	{
		"nvim-telescope/telescope.nvim",
		cmd = {
			"Telescope",
		},
		keys = {
			{ "<leader>m", "<cmd>Telescope marks<cr>", desc = "search by [M]arks" },
			{ "<leader>b", "<cmd>Telescope buffers<cr>", desc = "search by [B]uffers" },
			{ "<leader>f", "<cmd>Telescope find_files<cr>", desc = "search [F]iles" },
			{ "<leader>g", "<cmd>Telescope live_grep<cr>", desc = "search by [G]rep" },
			--{ "<leader>f", "<cmd>Telescope smart_open<cr>", desc = "search [F]iles with smart_open" },
			{ "<leader>H", "<cmd>Telescope help_tags<cr>", desc = "search [H]elp" },
			{ "<leader>d", "<cmd>Telescope diagnostics<cr>", desc = "search [D]iagnostics" },
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			telescope.setup({
				defaults = {
					path_display = { "truncate" },
					mappings = {
						i = {
							["<C-u>"] = false,
							["<C-d>"] = false,
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						},
					},
				},
			})

			telescope.load_extension("fzf")
			require("telescope-all-recent").setup({})
		end,
	},
}
