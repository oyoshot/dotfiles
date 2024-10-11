-- Git related plugins
return {
	{ "tpope/vim-rhubarb", lazy = true },

	{
		"tpope/vim-fugitive",
		event = { "BufReadPre", "BufNewFile" },
		cond = function()
			return not vim.g.vscode
		end,
		keys = {
			{ "git", mode = "c", "<cmd>Git<cr>", desc = "OpenGit" },
		},
	},
}
