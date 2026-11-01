return {
	-- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	cond = function()
		return not vim.g.vscode
	end,
	opts = {
		install_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter",
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
	},
	config = function(_, opts)
		local treesitter = require("nvim-treesitter")

		treesitter.setup({ install_dir = opts.install_dir })
		if vim.fn.executable("tree-sitter") == 1 then
			treesitter.install(opts.ensure_installed)
		else
			vim.notify(
				"tree-sitter CLI is required for nvim-treesitter parser installs. Install tree-sitter-cli.",
				vim.log.levels.ERROR
			)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
			callback = function()
				if pcall(vim.treesitter.start) then
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
