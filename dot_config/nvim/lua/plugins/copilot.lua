return {
	{
		"zbirenbaum/copilot.lua",
		event = "InsertEnter",
		opts = {
			suggestion = { enabled = false },
			panel = { enabled = false },
		},
	},
	{
		"zbirenbaum/copilot-cmp",
		event = "InsertEnter",
		dependencies = { "zbirenbaum/copilot.lua" },
		config = function()
			-- copilot-cmp still calls Client.is_stopped without `self`, which is
			-- deprecated on Neovim 0.12. Keep the source compatible until upstream updates.
			local source = require("copilot_cmp.source")
			source.is_available = function(self)
				if self.client.name ~= "copilot" or self.client:is_stopped() then
					return false
				end

				return #vim.lsp.get_clients({
					bufnr = vim.api.nvim_get_current_buf(),
					id = self.client.id,
				}) > 0
			end

			require("copilot_cmp").setup({})
		end,
	},
}
