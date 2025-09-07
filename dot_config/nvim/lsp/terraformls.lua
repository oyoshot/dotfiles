---@type vim.lsp.Config
return {
	on_attach = function(_, _)
		vim.env.PATH = "/usr/bin:" .. vim.env.PATH
	end,
}
