return {
	"romgrk/barbar.nvim",
	event = { "BufReadPost", "BufAdd", "BufNewFile" },
	init = function()
		vim.g.barbar_auto_setup = false
		-- barbar installs a watcher on this legacy option during setup.
		-- Neovim 0.12 errors when its setup removes missing watchers, so create
		-- the dictionary and the watchers that barbar replaces up front.
		vim.g.bufferline = vim.empty_dict()
		vim.cmd([[call dictwatcheradd(g:, 'bufferline', 'barbar#events#dict_changed')]])
		vim.cmd([[call dictwatcheradd(g:bufferline, '*', 'barbar#events#on_option_changed')]])
	end,
	opts = {
		-- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
		animation = true,
		-- insert_at_start = true,
		-- …etc.
	},
	version = "^1.0.0", -- optional: only update when a new 1.x version is released
}
