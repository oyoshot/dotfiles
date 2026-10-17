---@type vim.lsp.Config
return {
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json", "package.json", "node_modules" })
		if not root then
			return
		end
		on_dir(root)
	end,
	single_file_support = false,
}
