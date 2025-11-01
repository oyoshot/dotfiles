local function llm_history_dir()
	local nd = os.getenv("NOTES_DIR")
	if nd and nd ~= "" then
		nd = vim.fn.expand(nd)
		local target = vim.fs.joinpath(nd, "llm")
		if vim.fn.isdirectory(target) == 0 then
			vim.fn.mkdir(target, "p")
		end
		return target
	end
	local fallback = vim.fs.joinpath(vim.fn.stdpath("data"), "llm")
	vim.schedule(function()
		vim.notify(
			"[codecompanion-history] $NOTES_DIR が未設定のため " .. fallback .. " を使用します",
			vim.log.levels.WARN
		)
	end)
	if vim.fn.isdirectory(fallback) == 0 then
		vim.fn.mkdir(fallback, "p")
	end
	return fallback
end

return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
		"folke/noice.nvim",
		"zbirenbaum/copilot.lua",

		"ravitemer/codecompanion-history.nvim",
		"nvim-telescope/telescope.nvim",
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

		strategies = {
			chat = {
				roles = {
					llm = function(adapter)
						local name = adapter.formatted_name or adapter.name or "LLM"
						local model = adapter.parameters and adapter.parameters.model
						if not model and adapter.schema and adapter.schema.model then
							local def = adapter.schema.model.default
							model = type(def) == "function" and def(adapter) or def
						end

						return ("🤖 CodeCompanion (%s: %s)"):format(name, model or "?")
					end,
					user = "💬 Me",
				},
			},
			inline = {
				keymaps = {
					accept_changes = { modes = { n = "y" } },
					reject_changes = { modes = { n = "n" } },
					always_accept = { modes = { n = "a" } },
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
				opts = { is_slash_cmd = true, short_name = "review" },
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

			history = {
				enabled = true,
				opts = {
					auto_save = true,
					picker = "telescope",
					keymap = "<leader>h",
					save_chat_keymap = "sc",
					expiration_days = 0,
					dir_to_save = llm_history_dir(),
				},
			},
		},
	},

	config = function(_, opts)
		require("codecompanion").setup(opts)

		require("plugins.extensions.codecompanion-auto-export").setup()
	end,
}
