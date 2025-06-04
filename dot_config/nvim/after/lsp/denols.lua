---@type vim.lsp.Config
return {
	root_markers = { "deno.json", "deno.jsonc", "deps.ts" },
	workspace_required = true,
	settings = {
		deno = {
			inlayHints = {
				parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = true },
				parameterTypes = { enabled = true },
				variableTypes = { enabled = true, suppressWhenTypeMatchesName = true },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enable = true },
				enumMemberValues = { enabled = true },
			},
		},
	},
}
