return {
	"ray-x/go.nvim",
	dependencies = { -- optional packages
		"ray-x/guihua.lua",
		"neovim/nvim-lspconfig",
		"nvim-treesitter/nvim-treesitter",
	},
	lazy = true,
	ft = { "go", "gomod" },
	config = function()
		require("go").setup()
		vim.lsp.enable("gopls")
	end,
	event = { "CmdlineEnter" },
	build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
}
