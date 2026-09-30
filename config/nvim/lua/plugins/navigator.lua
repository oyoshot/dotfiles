return {
	{ "ray-x/guihua.lua", run = "cd lua/fzy && make" },

	{
		"ray-x/navigator.lua",
		cond = false,
		event = "LspAttach",
	},
}
