-- Diagnostic configuration
vim.diagnostic.config({
	float = {
		border = "rounded",
		source = true,
	},
	severity_sort = true,
	virtual_text = {
		source = "if_many",
		spacing = 2,
	},
})

-- Diagnostic keymaps
-- Note: [d and ]d are default keymaps in Neovim 0.10+
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
