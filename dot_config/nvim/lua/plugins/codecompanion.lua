return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
		"folke/noice.nvim",
	},
	init = function()
		require("plugins.extensions.codecompanion-noice").init()
	end,
	event = { "CursorHold", "CursorHoldI" },
	keys = {
		{ "<leader>ao", ":CodeCompanionChat openai<CR>", desc = "Chat with OpenAI" },
		{ "<leader>ac", ":CodeCompanionChat copilot<CR>", desc = "Chat with Copilot" },
		{ "<leader>am", ":MCPHub<CR>", desc = "Open MCP Hub UI" },
	},
	opts = {
		opts = { language = "Japanese" },

		display = {
			chat = {
				window = {
					position = "right",
				},
			},
		},

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

		prompt_library = {
			["Review (Web)"] = {
				strategy = "chat",
				description = "Web検索してコードレビュー",
				opts = {
					is_slash_cmd = true,
					short_name = "review",
				},
				prompts = {
					{
						role = "user",
						content = table.concat({
							"#{buffer}",
							"",
							"このコードをレビューしてください。まずローカル文脈のみで指摘を出し、",
							"判断がつかない箇所は直ちに @{ddg__search} または @{search_web} を実行して公式情報を確認し、",
							"最後に根拠URLを箇条書きで列挙してください。ツール実行の承認が必要なら実行して構いません。",
						}, "\n"),
					},
				},
			},
		},

		extensions = {
			mcphub = {
				callback = "mcphub.extensions.codecompanion",
				opts = {
					make_tools = true,
					make_vars = true,
					make_slash_commands = true,
					show_result_in_chat = true,
				},
			},
		},
	},
}
