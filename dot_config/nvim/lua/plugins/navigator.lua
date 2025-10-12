return {
	{ "ray-x/guihua.lua", run = "cd lua/fzy && make", lazy = true },

	{
		"ray-x/navigator.lua",
		cond = false,
		lazy = true,
		event = "LspAttach",
	},
}
