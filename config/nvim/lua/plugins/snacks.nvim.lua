local MIN_WIDTH = 24

local function scroll_to_depth(picker)
	local win = picker.list.win
	local item = picker:current()
	if picker.closed or not win:valid() or not item then
		return
	end
	local indent = Snacks.picker.format.tree(item, picker)[1][1]
	local width = vim.api.nvim_win_get_width(win.win)
	local leftcol = math.max(0, vim.fn.strdisplaywidth(indent) - math.max(0, width - MIN_WIDTH))
	vim.api.nvim_win_call(win.win, function()
		-- Entries at the same depth keep the same horizontal position.
		local cursor = vim.api.nvim_win_get_cursor(win.win)
		cursor[2] = #indent + 1
		vim.api.nvim_win_set_cursor(win.win, cursor)
		vim.fn.winrestview({ leftcol = leftcol })
	end)
end

return {
	"folke/snacks.nvim",
	keys = {
		{
			"<C-n>",
			function()
				Snacks.explorer()
			end,
			desc = "Toggle file explorer",
		},
	},
	opts = {
		explorer = {
			enabled = true,
			replace_netrw = false,
		},
		picker = {
			enabled = true,
			sources = {
				explorer = {
					hidden = true,
					ignored = true,
					on_change = scroll_to_depth,
					on_show = function(picker)
						-- Snacks resets leftcol before flushing the list; on_change runs afterwards.
						-- Remove when the picker preserves horizontal position during redraw.
						local redraw = picker.list.win.redraw
						picker.list.win.redraw = function(win)
							scroll_to_depth(picker)
							return redraw(win)
						end
						picker.list.win:on({ "WinResized", "VimResized" }, function()
							vim.schedule(function()
								scroll_to_depth(picker)
							end)
						end)
					end,
					formatters = {
						severity = { pos = "left" },
					},
					layout = {
						config = function(layout)
							layout.layout.width = math.min(40, math.max(MIN_WIDTH, math.floor(vim.o.columns * 0.3)))
							return layout
						end,
						layout = {
							min_width = MIN_WIDTH,
						},
					},
				},
			},
		},
	},
}
