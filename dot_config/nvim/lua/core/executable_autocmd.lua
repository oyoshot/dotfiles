-- ファイルを開いた時に、カーソルの場所を復元する
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  pattern = { "*" },
  callback = function()
    vim.api.nvim_exec('silent! normal! g`"zv', false)
  end,
})

-- 末尾の空白を削除する
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    pcall(function() vim.cmd [[%s/\s\+$//e]] end)
    vim.fn.setpos(".", save_cursor)
  end,
})

-- LF 書き換え
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function()
    vim.cmd [[ setlocal fileformat=unix ]]
  end,
})

-- Diagnostics Hover:
-- Besides inline diagnostics, if you want to hover over a piece of code to get a detailed error message, you can bind a key to show diagnostics under your cursor
vim.api.nvim_buf_set_keymap(0, 'n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>',
  { noremap = true, silent = true })

-- Set up hover on mouse move
-- vim.cmd([[
--  augroup LspHover
--    autocmd!
--    autocmd CursorHold * lua vim.lsp.buf.hover()
--  augroup END
-- ]])
--vim.cmd [[
--  augroup LspHoverDetails
--    autocmd! * <buffer>
--    autocmd CursorHold * lua vim.lsp.buf.hover()
--  augroup END
--]]
