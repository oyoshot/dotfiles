---@type vim.lsp.Config
return {
	before_init = function(_, config)
		local function typescript_lib(dir)
			local lib = vim.fs.joinpath(dir, "node_modules", "typescript", "lib")
			if vim.uv.fs_stat(vim.fs.joinpath(lib, "tsserverlibrary.js")) then
				return lib
			end
		end

		local tsdk = config.root_dir and typescript_lib(config.root_dir)
		if not tsdk and config.root_dir then
			for dir in vim.fs.parents(config.root_dir) do
				tsdk = typescript_lib(dir)
				if tsdk then
					break
				end
			end
		end

		if not tsdk then
			local result = vim.system({ "mise", "where", "npm:typescript" }, { text = true }):wait()
			if result.code == 0 then
				tsdk = typescript_lib(vim.trim(result.stdout))
			end
		end

		if tsdk then
			config.init_options = config.init_options or {}
			config.init_options.typescript = config.init_options.typescript or {}
			config.init_options.typescript.tsdk = tsdk
		end
	end,
}
