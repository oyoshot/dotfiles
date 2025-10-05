return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			dockerfile = { "hadolint" },
			terrafrom = { "tflint" },
			yaml = { "yamllint" },
			zsh = { "zsh" },
		}

		local aug = vim.api.nvim_create_augroup("UserNvimLint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost" }, {
			group = aug,
			callback = function()
				local max = 1024 * 1024 -- 1MB
				local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(0))
				if ok and stats and stats.size > max then
					return
				end
				lint.try_lint()
				require("lint").try_lint("cspell")
			end,
		})
	end,
}
