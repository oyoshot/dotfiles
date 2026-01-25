return {
	-- See `:help lualine.txt`
	-- Set lualine as statusline
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"lewis6991/gitsigns.nvim",
	},
	lazy = true,
	event = { "BufReadPost", "BufAdd", "BufNewFile" },
	config = function()
		local lualine = require("lualine")
		local catppuccined = require("lualine.themes.catppuccin")

		local palette = require("catppuccin.palettes").get_palette()
		local segment = { fg = palette.subtext1, bg = palette.surface1 }
		local muted = vim.deepcopy(catppuccined)
		for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "terminal", "inactive" }) do
			muted[mode] = {
				a = segment,
				b = segment,
				c = segment,
			}
		end

		local function diff_source()
			local gitsigns = vim.b.gitsigns_status_dict
			if gitsigns then
				return {
					added = gitsigns.added,
					modified = gitsigns.changed,
					removed = gitsigns.removed,
				}
			end
		end

		local current = nil
		local function setup_lualine(theme)
			if current == theme then
				return
			end
			current = theme
			lualine.setup({
				options = {
					theme = theme,
				},
				sections = {
					lualine_b = { { "diff", source = diff_source } },
				},
			})
			lualine.refresh()
		end
		setup_lualine(catppuccined)

		local is_inactive = false
		local function set_inactive(v)
			if is_inactive == v then
				return
			end
			is_inactive = v
			vim.schedule(function()
				setup_lualine(v and muted or catppuccined)
			end)
		end

		local group = vim.api.nvim_create_augroup("LualineFocusTheme", { clear = true })
		vim.api.nvim_create_autocmd("FocusGained", {
			group = group,
			callback = function()
				set_inactive(false)
			end,
		})
		vim.api.nvim_create_autocmd("FocusLost", {
			group = group,
			callback = function()
				set_inactive(true)
			end,
		})
	end,
}
