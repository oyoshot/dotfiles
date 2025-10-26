return {
	"olimorris/codecompanion.nvim",
	event = { "CursorHold", "CursorHoldI" },
	dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
	opts = {
		opts = {
			language = "Japanese",
		},
		strategies = {
			chat = { adapter = "copilot" },
			inline = { adapter = "copilot" },
		},
	},
	keys = {
		{
			"<leader>ac",
			function()
				require("codecompanion").chat()
			end,
			desc = "CodeCompanion: Chat",
		},
		{
			"<leader>at",
			function()
				require("codecompanion").toggle()
			end,
			desc = "CodeCompanion: Toggle chat",
		},
	},
}
