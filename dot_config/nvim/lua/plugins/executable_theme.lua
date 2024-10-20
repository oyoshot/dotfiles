return {
	{
		"navarasu/onedark.nvim",
		event = "VimEnter",
		cond = false,
	},

	{
		"rebelot/kanagawa.nvim",
		event = "VimEnter",
		priority = 1000,
		cond = false,
		config = function()
			vim.cmd.colorscheme("kanagawa")
		end,
	},

	{
		"ayu-theme/ayu-vim",
		-- cond = false,
		event = "VimEnter",
		priority = 1000,
		cond = function()
			-- return not vim.g.vscode
			return false
		end,
		config = function()
			-- 背景透過
			--vim.cmd([[hi! Normal ctermbg=NONE guibg=NONE]])
			vim.g.ayucolor = "dark" -- for dark version of theme
			vim.cmd.colorscheme("ayu")
			vim.api.nvim_exec(
				[[
        highlight Visual guibg=#555555
      ]],
				false
			)
		end,
	},

	{
		"catppuccin/nvim",
		event = "VimEnter",
		priority = 1000,
		name = "catppuccin",
		opts = {
			term_colors = true,
			transparent_background = true,
			default_integrations = true,
			integrations = {
				lsp_trouble = true,
				mason = true,
				which_key = true,
				noice = true,
				notify = true,
			},
		},
		config = function()
			vim.cmd.colorscheme("catppuccin")
			vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
			vim.cmd("hi NormalNC guibg=NONE ctermbg=NONE")
			vim.cmd("hi LspInlayHint guibg=NONE ctermbg=NONE")
		end,
	},

	{
		"4513ECHO/vim-colors-hatsunemiku",
		event = "VimEnter",
		cond = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("hatsunemiku")
		end,
	},

	{
		"rose-pine/neovim",
		event = "VimEnter",
		priority = 1000,
		cond = false,
		name = "rose-pine",
		opts = {
			variant = "dawn",
		},
		config = function()
			vim.cmd.colorscheme("rose-pine")
		end,
	},

	{
		"kyoh86/momiji",
		cond = false,
		priority = 1000,
	},
}
