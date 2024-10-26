-- Git related plugins
return {
	{ "tpope/vim-rhubarb", lazy = true },

	{
		"tpope/vim-fugitive",
		lazy = true,
		event = { "CursorHold", "CursorHoldI" },
		cond = function()
			return not vim.g.vscode
		end,
		keys = {
			{ "git", mode = "c", "<cmd>Git<cr>", desc = "OpenGit" },
		},
	},
}
