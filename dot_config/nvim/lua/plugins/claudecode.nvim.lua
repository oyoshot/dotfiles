return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	lazy = true,
	opts = {
		terminal = {
			snacks_win_opts = {
				wo = {
					winhighlight = "",
				},
			},
		},
	},
	config = function(_, opts)
		require("claudecode").setup(opts)

		-- Send and focus command
		vim.api.nvim_create_user_command("ClaudeCodeSendAndFocus", function(cmd_opts)
			if cmd_opts.range > 0 then
				vim.cmd(string.format("%d,%dClaudeCodeSend", cmd_opts.line1, cmd_opts.line2))
			else
				vim.cmd("ClaudeCodeSend")
			end
			vim.defer_fn(function()
				vim.cmd("ClaudeCodeFocus")
			end, 100)
		end, { range = true })
	end,

	keys = {
		{ "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Claude toggle" },
		{ "<leader>ccs", "<cmd>ClaudeCodeSendAndFocus<cr>", desc = "Claude send and focus" },
		{ "<leader>ccs", ":'<,'>ClaudeCodeSendAndFocus<cr>", mode = "v", desc = "Claude send and focus" },
	},

	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeSelectModel",
		"ClaudeCodeSend",
		"ClaudeCodeSendAndFocus",
		"ClaudeCodeAdd",
		"ClaudeCodeDiffAccept",
		"ClaudeCodeDiffDeny",
	},
}
