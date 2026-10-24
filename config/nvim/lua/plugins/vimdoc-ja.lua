return {
	"vim-jp/vimdoc-ja",
	-- Neovim 0.12 rewrites the tracked tags-ja file while generating helptags.
	-- Restore the upstream file so Lazy does not treat the plugin as modified.
	build = "git restore -- doc/tags-ja",
	keys = {
		{ "h", mode = "c", desc = "open [H]elp" },
	},
}
