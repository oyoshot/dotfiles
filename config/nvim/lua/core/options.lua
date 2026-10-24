-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- :help options
vim.o.backup = false -- creates a backup file

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Force LF
-- vim.o.fileformat = "unix"

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- https://vim-jp.org/vimdoc-ja/options.html#'ambiwidth
vim.o.ambiwidth = "single"

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeout = true
vim.opt.timeoutlen = 500

-- NOTE: You should make sure your terminal supports this
-- vim.o.winblend = 20
vim.o.winblend = 0
-- vim.o.pumblend = 20
vim.o.pumblend = 0
vim.o.termguicolors = true

-- vim doc ja
vim.o.helplang = "ja,en"

-- tab
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4

-- other
vim.o.autoread = true
vim.o.incsearch = true
vim.o.autoindent = true
vim.o.laststatus = 2

-- Inherit the selected project environment.
-- GUI launches may lack the user profile and interactive mise activation.
local mise_data = vim.env.MISE_DATA_DIR or ((vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")) .. "/mise")
local fallback_paths = { mise_data .. "/shims" }
if not vim.env.IN_NIX_SHELL then
	table.insert(fallback_paths, (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/nix/profile/bin")
end
local paths = vim.split(vim.env.PATH or "", ":", { plain = true })
local system_paths = {
	["/usr/bin"] = true,
	["/usr/sbin"] = true,
	["/bin"] = true,
	["/sbin"] = true,
	["/usr/local/bin"] = true,
	["/usr/local/sbin"] = true,
	["/opt/homebrew/bin"] = true,
	["/opt/homebrew/sbin"] = true,
	["/nix/var/nix/profiles/default/bin"] = true,
	["/run/current-system/sw/bin"] = true,
}
local insert_at = #paths + 1
for index, path in ipairs(paths) do
	if system_paths[path] or vim.tbl_contains(fallback_paths, path) then
		insert_at = index
		break
	end
end
-- Normalize global fallbacks even when inherited, keeping project prefixes first.
paths = vim.tbl_filter(function(path)
	return not vim.tbl_contains(fallback_paths, path)
end, paths)
-- mise project overrides must precede the global Nix defaults.
for _, path in ipairs(fallback_paths) do
	table.insert(paths, insert_at, path)
	insert_at = insert_at + 1
end
vim.env.PATH = table.concat(paths, ":")

vim.filetype.add({
	extension = {
		gotmpl = "gotmpl",
		mdx = "markdown.mdx",
	},
})
