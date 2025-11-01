return {
	"ravitemer/mcphub.nvim",
	lazy = true,
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("mcphub").setup({
			use_bundled_binary = false,
		})
	end,
}
