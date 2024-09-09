return {
	{
		"Wansmer/treesj",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("treesj").setup({})
			vim.keymap.set("n", "<leader>s", require("treesj").toggle)
		end,
	},
}
