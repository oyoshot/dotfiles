local TRASH = (vim.fn.executable("trash-put") == 1 and { "trash-put" })
	or (vim.fn.executable("gio") == 1 and { "gio", "trash" })
	or nil

local function normalize_nodes(state, nodes)
	if not nodes or #nodes == 0 then
		local node = state.tree:get_node()
		return node and { node } or {}
	end
	if type(nodes[1]) ~= "table" then
		local out = {}
		for _, id in ipairs(nodes) do
			local node = state.tree:get_node(id)
			if node then
				table.insert(out, node)
			end
		end
		return out
	end
	return nodes
end

local function do_trash(state, nodes)
	local fs_cmds = require("neo-tree.sources.filesystem.commands")
	local inputs = require("neo-tree.ui.inputs")

	nodes = normalize_nodes(state, nodes)
	if #nodes == 0 then
		return
	end

	if not TRASH then
		return fs_cmds.delete_visual(state, nodes)
	end

	inputs.confirm("選択項目をゴミ箱へ移動しますか？", function(ok)
		if not ok then
			return
		end

		local manager = require("neo-tree.sources.manager")
		local pending = 0

		for _, node in ipairs(nodes) do
			if node.type ~= "message" then
				local a = vim.deepcopy(TRASH)
				table.insert(a, node.path)
				pending = pending + 1
				vim.fn.jobstart(a, {
					detach = false,
					on_exit = function(_, _code, _signal)
						pending = pending - 1
						if pending == 0 then
							vim.schedule(function()
								manager.refresh(state)
							end)
						end
					end,
				})
			end
		end
	end)
end

local function cmd_trash(state)
	do_trash(state)
end

local function cmd_trash_visual(state, selected_nodes)
	do_trash(state, selected_nodes)
end

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		-- not strictly required, but recommended
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
		-- Optional image support in preview window: See `# Preview Mode` for more information
		"3rd/image.nvim",
	},
	lazy = true,
	keys = {
		{ "<C-n>", "<CMD>Neotree toggle<CR>", desc = "Toggle file explorer" },
	},
	opts = {
		default_component_configs = {
			git_status = {
				symbols = {
					added = "✚",
					modified = "",
				},
			},
		},
		filesystem = {
			filtered_items = {
				-- visible = true,
				hide_dotfiles = false,
				hide_gitignored = true,
				never_show = { ".git" },
			},
			window = {
				mappings = {
					["d"] = "trash",
					["D"] = "delete",
				},
			},
		},
		commands = {
			trash = cmd_trash,
			trash_visual = cmd_trash_visual,
		},
	},

	config = function(_, opts)
		require("neo-tree").setup(opts)

		local function apply()
			local set = vim.api.nvim_set_hl
			set(0, "NeoTreeNormal", { bg = "none" })
			set(0, "NeoTreeNormalNC", { bg = "none" })
			set(0, "NeoTreeEndOfBuffer", { bg = "none" })
			set(0, "NeoTreeWinSeparator", { bg = "none" })
		end
		apply()
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				vim.schedule(apply)
			end,
		})
	end,
}
