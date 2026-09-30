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

-- Inherit the selected project environment; adding shims here bypasses Nix shells.
-- GUI launches may lack the user profile, so append only the common tools path.
if not vim.env.IN_NIX_SHELL and not vim.env.DOTFILES_NIX_SHELL then
	local profile = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/nix/profile/bin"
	if not (":" .. vim.env.PATH .. ":"):find(":" .. profile .. ":", 1, true) then
		vim.env.PATH = vim.env.PATH .. ":" .. profile
	end
end

vim.filetype.add({
	extension = {
		gotmpl = "gotmpl",
		mdx = "markdown.mdx",
	},
})
