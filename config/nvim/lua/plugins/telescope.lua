return {
	{ "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" },
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{ "prochri/telescope-all-recent.nvim", opts = {} },
	{ "kkharji/sqlite.lua" },

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
			{
				"<leader>w",
				":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
				desc = "search [W]ord with args",
			},
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			-- Search dotfiles such as .zshrc, but not .git: a directory in a
			-- normal clone and a file in a linked worktree.
			local exclude_git = { "--glob=!**/.git/*", "--glob=!**/.git" }
			local vimgrep_arguments = vim.list_extend(
				vim.deepcopy(require("telescope.config").values.vimgrep_arguments),
				exclude_git
			)
			telescope.setup({
				defaults = {
					path_display = { "truncate" },
					vimgrep_arguments = vimgrep_arguments,
					mappings = {
						i = {
							["<C-u>"] = false,
							["<C-d>"] = false,
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						},
					},
				},
				-- `hidden` lets a single call opt out, e.g. `:Telescope find_files hidden=false`.
				pickers = {
					find_files = {
						hidden = true,
						find_command = vim.list_extend({ "rg", "--files", "--color", "never" }, exclude_git),
					},
					live_grep = { hidden = true },
					grep_string = { hidden = true },
				},
				extensions = {
					-- live_grep_args has no `hidden` option; type `--no-hidden` in the prompt to opt out.
					live_grep_args = {
						vimgrep_arguments = vim.list_extend(vim.deepcopy(vimgrep_arguments), { "--hidden" }),
					},
				},
			})

			telescope.load_extension("fzf")
			require("telescope-all-recent").setup({})
		end,
	},
}
