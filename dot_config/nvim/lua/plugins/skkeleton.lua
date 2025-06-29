local function dict(name, file, enc)
	local base = vim.fn.stdpath("data") .. "/lazy/"
	return { base .. name .. "/" .. file, enc }
end

---@type LazyPluginSpec[]
return {
	{ "uasi/skk-emoji-jisyo", name = "skk-emoji-en", lazy = true },
	{ "ymrl/SKK-JISYO.emoji-ja", name = "skk-emoji-ja", lazy = true },

	{
		"vim-skk/skkeleton",

		dependencies = {
			"vim-denops/denops.vim",
			"aosc-dev/skk-jisyo",
			"skk-emoji-en",
			"skk-emoji-ja",
		},

		event = { "InsertEnter" },

		build = function()
			local dir = vim.fn.stdpath("data") .. "/skk"
			vim.fn.mkdir(dir, "p")
		end,

		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "skkeleton-initialize-pre",

				callback = function()
					vim.fn["skkeleton#config"]({
						eggLikeNewline = true,
						globalDictionaries = {
							dict("skk-jisyo", "SKK-JISYO.L", "euc-jp"),
							dict("skk-emoji-en", "SKK-JISYO.emoji.utf8", "utf-8"),
							dict("skk-emoji-ja", "SKK-JISYO.emoji-ja.utf8", "utf-8"),
						},
						userDictionary = vim.fn.stdpath("data") .. "/skk/user_jisyo",
					})

					vim.fn["skkeleton#register_kanatable"]("rom", {
						jj = "escape",
					})
				end,
			})
		end,

		config = function()
			vim.keymap.set({ "i", "c" }, "<C-j>", "<Plug>(skkeleton-toggle)")
		end,
	},

	{
		"delphinus/skkeleton_indicator.nvim",
		event = { "InsertEnter" },
		lazy = true,
		opts = {},
	},
}
