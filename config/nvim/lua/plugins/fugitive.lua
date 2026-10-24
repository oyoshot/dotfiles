-- Git related plugins
return {
	{ "tpope/vim-rhubarb" },

	{
		"tpope/vim-fugitive",
		event = { "CursorHold", "CursorHoldI" },
		cond = function()
			return not vim.g.vscode
		end,
		keys = {
			{ "git", mode = "c", "<cmd>Git<cr>", desc = "OpenGit" },
		},
	},
}
