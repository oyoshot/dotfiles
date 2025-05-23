---@type vim.lsp.Config
return {
	on_attach = function(_, _)
		print("hello gopls")
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.go",
			callback = function()
				vim.lsp.buf.code_action({
					context = { only = { "source.organizeImports" } },
					apply = true,
				})
			end,
		})
	end,
}
