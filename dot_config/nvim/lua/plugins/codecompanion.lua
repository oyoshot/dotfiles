return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
	},
	event = { "CursorHold", "CursorHoldI" },
	keys = {
		{ "<leader>ao", ":CodeCompanionChat openai<CR>", desc = "Chat with OpenAI" },
		{ "<leader>ac", ":CodeCompanionChat copilot<CR>", desc = "Chat with Copilot" },
		{ "<leader>am", ":MCPHub<CR>", desc = "Open MCP Hub UI" },
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

			["Docs (inline)"] = {
				strategy = "inline",
				description = "選択範囲に言語ごとのドキュメントコメントを挿入/更新",
				opts = {
					is_slash_cmd = true,
					short_name = "docs",
					requires_selection = true,
					auto_submit = true,
				},
				prompts = {
					{
						role = "user",
						content = table.concat({
							"#{visual}",
							"",
							"上のコード片の直前（または既存コメントの該当位置）に、言語/フレームワークの慣習に沿った",
							"ドキュメントコメント（docstring/JSDoc/GoDoc/Doxygen/EmmyLua など）を追加または更新してください。",
							"",
							"ルール:",
							"- 言語を自動判定し、適切なスタイルで記述（例: Python→Google/NumPy docstring, TS/JS→JSDoc, Go→GoDoc, Rust→///, C/C++→Doxygen, Lua→---@param/@return）。",
							"- 引数・戻り値・例外・前提条件・副作用・使用例（該当時）を簡潔に。",
							"- 既存のコメントがあれば重複を避けて統合し、質を上げる。",
							"- コード本体の挙動は変更しない（コメント追加/更新のみ）。",
							"- 日本語でわかりやすく。API名など英語のままが自然な箇所は英語のまま。",
							"- 70〜100桁程度で適宜改行。",
							"",
							"最終出力は、編集後の完全なコードのみを返してください（説明文や余計なテキストは不要）。",
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
