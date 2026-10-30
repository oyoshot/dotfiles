---@type vim.lsp.Config
return {
	cmd = function(dispatchers, config)
		local root_dir = (config or {}).root_dir
		if type(root_dir) == "string" then
			local local_cmd = vim.fs.joinpath(root_dir, ".venv", "bin", "pyright-langserver")
			if vim.fn.executable(local_cmd) == 1 then
				return vim.lsp.rpc.start({ local_cmd, "--stdio" }, dispatchers)
			end
		end

		return vim.lsp.rpc.start({ "pyright-langserver", "--stdio" }, dispatchers)
	end,
	on_init = function(client)
		local root_dir = client.root_dir
		if type(root_dir) ~= "string" then
			return
		end

		local python = vim.fs.joinpath(root_dir, ".venv", "bin", "python")
		if vim.fn.executable(python) == 1 then
			client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
				python = {
					pythonPath = python,
				},
			})
			client:notify("workspace/didChangeConfiguration", { settings = nil })
		end
	end,
	settings = {
		pyright = {
			-- Using Ruff's import organizer
			disableOrganizeImports = true,
		},
	},
}
