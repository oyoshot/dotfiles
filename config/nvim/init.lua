--    _      _ __    __
--   (_)__  (_) /_  / /_ _____ _
--  / / _ \/ / __/ / / // / _ `/
-- /_/_//_/_/\__(_)_/\_,_/\_,_/
--

-- Disable legacy remote-plugin providers that this config does not use.
-- External commands such as `python3` remain available to plugins.
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

if vim.g.vscode then
	require("core/vscode")
else
	require("core/keymaps")
	require("core/autocmd")
	require("core/lazyvim")
	require("core/options")
	require("core/diagnostics")
end
