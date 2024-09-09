return {
	-- optional packages
	{ "ray-x/guihua.lua", lazy = true },
	{ "neovim/nvim-lspconfig", lazy = true },
	{ "nvim-treesitter/nvim-treesitter", lazy = true },

	{
		"ray-x/go.nvim",

		ft = { "go", "gomod" },
		config = function()
			require("go").setup()
		end,
		build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
	},
}
