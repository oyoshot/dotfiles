return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
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
		{
			"<leader>am",
			":MCPHub<CR>",
			desc = "Open MCP Hub UI",
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
		extensions = {
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					make_tools = true,
					make_vars = true,
					make_slash_commands = true,
					show_server_tools_in_chat = true,
				},
			},
		},
	},
}
