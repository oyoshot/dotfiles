local function parse_textlint_json(output, _)
	if not output or output == "" then
		return {}
	end
	local ok, decoded = pcall(vim.json.decode, output)
	if not ok or type(decoded) ~= "table" then
		return {}
	end

	local diags = {}
	for _, fileRes in ipairs(decoded) do
		for _, m in ipairs(fileRes.messages or {}) do
			local sline = m.line or (m.loc and m.loc.start and m.loc.start.line) or 1
			local scol = m.column or (m.loc and m.loc.start and m.loc.start.column) or 1
			local eline = m.endLine or (m.loc and m.loc["end"] and m.loc["end"].line) or sline
			local ecol = m.endColumn or (m.loc and m.loc["end"] and m.loc["end"].column) or scol

			diags[#diags + 1] = {
				lnum = math.max(sline - 1, 0),
				col = math.max(scol - 1, 0),
				end_lnum = math.max(eline - 1, 0),

				end_col = math.max(ecol - 1, 0),
				message = m.message or "",
				code = m.ruleId,
				source = "textlint",
				severity = (m.severity == 2) and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
			}
		end
	end
	return diags
end

return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters.cspell = require("lint").linters.cspell
		lint.linters.cspell.args = {
			"lint",
			"--no-color",
			"--no-progress",
			"--no-summary",
			"--config",
			vim.fn.expand("~/.config/cspell/cspell.json"),
			function()
				return "stdin://" .. vim.api.nvim_buf_get_name(0)
			end,
		}

		lint.linters.textlint = {
			cmd = "textlint",
			prefer_local = "node_modules/.bin",
			stdin = true,
			append_fname = false,
			args = {
				"--format",
				"json",
				"--stdin",
				"--stdin-filename",
				function()
					return vim.api.nvim_buf_get_name(0)
				end,
			},
			stream = "stdout",
			ignore_exitcode = true,
			parser = parse_textlint_json,
		}

		lint.linters_by_ft = {
			dockerfile = { "hadolint" },
			terraform = { "tflint" },
			yaml = { "yamllint" },
			zsh = { "zsh" },
		}

		local aug = vim.api.nvim_create_augroup("UserNvimLint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost" }, {
			group = aug,
			callback = function()
				local max = 1024 * 1024
				local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(0))
				if ok and stats and stats.size > max then
					return
				end

				lint.try_lint()
				lint.try_lint("cspell")
				lint.try_lint("textlint")
			end,
		})
	end,
}
