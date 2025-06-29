---@type vim.lsp.Config
return {
	filetypes = { "sh", "zsh", "bash" },
	settings = {
		bashIde = {
			globPattern = "**/*@(.sh|.bash|.zsh|.zshrc|.zprofile)",
			shellcheckArguments = "--shell=bash",
		},
	},
}
