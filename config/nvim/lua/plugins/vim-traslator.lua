return {
	"uga-rosa/translate.nvim",
	keys = {
		{ "tt", mode = { "n", "v" } },
	},
	config = function()
		require("translate").setup({})
		vim.keymap.set({ "n", "v" }, "t", "<Cmd>Translate ja<CR>")
	end,
}
