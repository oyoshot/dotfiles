return {
	"keaising/im-select.nvim",
	lazy = true,
	event = "InsertEnter",
	cond = function()
		if vim.fn.has("wsl") == 1 then
			return false
		end
	end,
	config = function()
		require("im_select").setup({})
	end,
}
