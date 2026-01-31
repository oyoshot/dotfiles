return {
	-- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	lazy = true,
	event = { "BufReadPost", "BufNewFile" },
	build = ":TSUpdate",
	cmd = { "TSUpdateSync" },
	cond = function()
		return not vim.g.vscode
	end,
	opts = {
		ensure_installed = {
			"astro",
			"go",
			"gosum",
			"gomod",
			"gowork",
			"lua",
			"python",
			"rust",
			"typescript",
			"tsx",
			"vimdoc",
			"vim",
			"kotlin",
			"dockerfile",
			"json",
			"json5",
			"jsonc",
			"terraform",
			"hcl",
			"bash",
			"c",
			"html",
			"javascript",
			"jsdoc",
			"luadoc",
			"luap",
			"markdown",
			"markdown_inline",
			"query",
			"regex",
			"yaml",
			"toml",
			"ron",
		},
		-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
		auto_install = true,
		highlight = { enable = true },
		indent = { enable = true },
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<c-space>",
				node_incremental = "<c-space>",
				scope_incremental = "<c-s>",
				node_decremental = "<M-space>",
			},
		},
	},
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)
	end,
}
