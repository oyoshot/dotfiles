return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	lazy = true,
	config = true,

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
