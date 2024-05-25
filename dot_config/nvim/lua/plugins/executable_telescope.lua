return {
	{
		"nvim-telescope/telescope.nvim",
		cmd = {
			"Telescope",
		},
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{ "<leader>m", "<cmd>Telescope marks<cr>", desc = "search by [M]arks" },
			{ "<leader>f", "<cmd>Telescope smart_open<cr>", desc = "search [F]iles" },
			{ "<leader>g", "<cmd>Telescope live_grep<cr>", desc = "search by [G]rep" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-tree/nvim-web-devicons",
			--"prochri/telescope-all-recent.nvim",
			"prochri/telescope-all-recent.nvim",
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			telescope.setup({
				defaults = {
					path_display = { "truncate " },
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
			-- See `:help telescope.builtin`
			-- vim.keymap.set('n', '<leader>f', require('telescope.builtin').find_files, { desc = 'search [F]iles' })
			-- vim.keymap.set('n', '<leader>g', require('telescope.builtin').live_grep, { desc = 'search by [G]rep' })
			-- vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
			-- vim.keymap.set('n', '<leader>b', require('telescope.builtin').buffers, { desc = 'Find existing [B]uffers' })
			vim.keymap.set("n", "<leader>H", require("telescope.builtin").help_tags, { desc = "search [H]elp" })
			vim.keymap.set(
				"n",
				"<leader>w",
				require("telescope.builtin").grep_string,
				{ desc = "search current [W]ord" }
			)
			-- vim.keymap.set('n', '<leader>d', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
		end,
	},

	{
		"prochri/telescope-all-recent.nvim",
		event = { "BufReadPre", "BufNewFile" },
		cond = false,
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"kkharji/sqlite.lua",
			-- optional, if using telescope for vim.ui.select
			-- "stevearc/dressing.nvim",
		},
		opts = {},
	},

	{
		"danielfalk/smart-open.nvim",
		branch = "0.2.x",
		dependencies = {
			"kkharji/sqlite.lua",
			-- Only required if using match_algorithm fzf
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			-- Optional.  If installed, native fzy will be used when match_algorithm is fzy
			{ "nvim-telescope/telescope-fzy-native.nvim" },
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("telescope").load_extension("smart_open")
		end,
	},
}
