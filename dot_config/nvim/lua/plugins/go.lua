return {
	-- optional packages
	{ "ray-x/guihua.lua", lazy = true },

	{
		"ray-x/go.nvim",
		lazy = true,
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
		opts = {},
	},
}
