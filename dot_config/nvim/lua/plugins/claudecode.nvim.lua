return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	lazy = true,
	config = function()
		require("claudecode").setup()

		-- Send and focus command
		vim.api.nvim_create_user_command("ClaudeCodeSendAndFocus", function(opts)
			if opts.range > 0 then
				vim.cmd(string.format("%d,%dClaudeCodeSend", opts.line1, opts.line2))
			else
				vim.cmd("ClaudeCodeSend")
			end
			vim.defer_fn(function()
				vim.cmd("ClaudeCodeFocus")
			end, 100)
		end, { range = true })
	end,

	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSelectModel",
		"ClaudeCodeSend",
		"ClaudeCodeAdd",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
	},
}
