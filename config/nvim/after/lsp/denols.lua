---@type vim.lsp.Config
return {
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
		if not root then
			return
		end
		on_dir(root)
	end,
	single_file_support = false,
	settings = {
		deno = { enable = true },
	},
}
