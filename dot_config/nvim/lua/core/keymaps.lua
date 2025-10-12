-- [[ Basic Keymaps ]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opts = { noremap = true }

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- for US keyboard
vim.keymap.set({ "n", "x", "s" }, ":", ";", opts)
vim.keymap.set({ "n", "x", "s" }, ";", ":", opts)

-- Move to the end of the line
vim.keymap.set("n", "<Leader>h", "^", opts)
vim.keymap.set("n", "<Leader>l", "$", opts)

-- Split buffer
vim.keymap.set("n", "ss", ":split<Return><C-w>w", opts)
vim.keymap.set("n", "sv", ":vsplit<Return><C-w>w", opts)

-- Move buffer
vim.keymap.set("n", "sh", "<C-w>h", opts)
vim.keymap.set("n", "sj", "<C-w>j", opts)
vim.keymap.set("n", "sk", "<C-w>k", opts)
vim.keymap.set("n", "sl", "<C-w>l", opts)

vim.keymap.set("n", "<Tab>", ":bnext<CR>", opts)
vim.keymap.set("n", "<S-Tab>", ":bprev<CR>", opts)

-- Select all
vim.keymap.set("n", "<Leader>a", "gg<S-v>G", opts)

-- No yank with x
vim.keymap.set("n", "x", '"_x', opts)

-- Insert Mode
vim.keymap.set("i", "jj", "<ESC>", opts)
vim.keymap.set("i", "<C-b>", "<BS>", opts)
vim.keymap.set("i", "<C-d>", "<Del>", opts)
vim.keymap.set("i", "<C-h>", "<Left>", opts)
vim.keymap.set("i", "<C-j>", "<Down>", opts)
vim.keymap.set("i", "<C-k>", "<Up>", opts)
vim.keymap.set("i", "<C-l>", "<Right>", opts)

-- Visual Mode
vim.keymap.set({ "v", "x" }, "v", "<ESC>", opts)
vim.keymap.set({ "v", "x" }, "<Leader>h", "^", opts)
vim.keymap.set({ "v", "x" }, "<Leader>l", "$h", opts)
vim.keymap.set("v", ">", ">gv", opts)
vim.keymap.set("v", "<", "<gv", opts)
