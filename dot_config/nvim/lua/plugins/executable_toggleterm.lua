return {
	"akinsho/toggleterm.nvim",
	lazy = true,
	keys = {
		{ "<leader>L", "<cmd>lua _lazygit_toggle()<CR>", desc = "open [L]azygit" },
	},
	opts = {
		autochdir = true,
	},
	config = function()
		local Terminal = require("toggleterm.terminal").Terminal
		local lazygit = Terminal:new({ cmd = "lazygit", direction = "float", hidden = true })
		function _lazygit_toggle()
			lazygit:toggle()
		end
	end,
}
