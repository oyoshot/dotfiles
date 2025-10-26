return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	event = { "CursorHold", "CursorHoldI" },
	keys = {
		{
			"<leader>ao",
			":CodeCompanionChat openai<CR>",
			desc = "Chat with OpenAI",
		},
		{
			"<leader>ac",
			":CodeCompanionChat copilot<CR>",
			desc = "Chat with Copilot",
		},
	},
	opts = {
		opts = { language = "Japanese" },
		adapters = {
			http = {
				openai = function()
					return require("codecompanion.adapters").extend("openai", {
						env = { OPENAI_API_KEY = os.getenv("OPENAI_API_KEY") },
					})
				end,
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {})
				end,
			},
		},
		-- strategies = {
		-- 	chat = { adapter = "openai" },
		-- 	inline = { adapter = "openai" },
		-- },
	},
}
