local M = {}

M.debounce_ms = 2000
M.subdir = { "llm", "export" }
M.tagline = 'tags: ["llm","codecompanion","auto-export"]'

local function ensure_dir(p)
	if vim.fn.isdirectory(p) == 0 then
		vim.fn.mkdir(p, "p")
	end
end

local function export_dir()
	local nd = os.getenv("NOTES_DIR")
	if nd and nd ~= "" then
		nd = vim.fn.expand(nd)
		local dir = vim.fs.joinpath(nd, unpack(M.subdir))
		ensure_dir(dir)
		return dir
	end
	local fb = vim.fs.joinpath(vim.fn.stdpath("data"), "cc-export")
	ensure_dir(fb)
	vim.schedule(function()
		vim.notify("[cc-auto-export] $NOTES_DIR 未設定のため " .. fb .. " を使用", vim.log.levels.WARN)
	end)
	return fb
end

local function slug(s)
	s = (s or "chat"):gsub('[/\\:?*"<>|]', " "):gsub("%s+", "-"):gsub("%.-$", "")
	if s == "" then
		s = "chat"
	end
	return s
end

local function filename(chat, bufnr)
	local base = ("%s_%s.md"):format(slug(chat.title or "chat"), tostring(chat.id or bufnr))
	return vim.fs.joinpath(export_dir(), base)
end

local function write_markdown(bufnr)
	local ok, chat = pcall(function()
		return require("codecompanion").buf_get_chat(bufnr)
	end)
	if not ok or not chat then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local header = {
		"---",
		M.tagline,
		"title: " .. (chat.title or "CodeCompanion Chat"),
		"updated: " .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
		"---",
		"",
	}
	local all = {}
	vim.list_extend(all, header)
	vim.list_extend(all, lines)

	local path = filename(chat, bufnr)
	vim.fn.writefile(all, path)
	vim.schedule(function()
		vim.notify("[cc-auto-export] wrote " .. path, vim.log.levels.DEBUG)
	end)
end

local state = {} -- bufnr -> {timer}
local function ensure_timer(bufnr)
	if state[bufnr] and not state[bufnr].closed then
		return state[bufnr].timer
	end
	local uv = vim.uv or vim.loop
	local t = uv.new_timer()
	state[bufnr] = { timer = t, closed = false }
	return t
end

local function schedule(bufnr)
	local t = ensure_timer(bufnr)
	t:stop()
	t:start(M.debounce_ms, 0, function()
		t:stop()
		vim.schedule(function()
			if vim.api.nvim_buf_is_loaded(bufnr) then
				write_markdown(bufnr)
			end
		end)
	end)
end

local function detach(bufnr)
	local s = state[bufnr]
	if s and not s.closed then
		s.closed = true
		if s.timer then
			local ok = pcall(function()
				s.timer:stop()
				s.timer:close()
			end)
			if not ok then -- ignore
			end
		end
		state[bufnr] = nil
	end
end

function M.setup()
	local aug = vim.api.nvim_create_augroup("CCAutoExport", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		group = aug,
		callback = function(args)
			local ok, chat = pcall(function()
				return require("codecompanion").buf_get_chat(args.buf)
			end)
			if not ok or not chat then
				return
			end

			write_markdown(args.buf)
			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
				group = aug,
				buffer = args.buf,
				callback = function()
					schedule(args.buf)
				end,
			})
			vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout", "BufUnload" }, {
				group = aug,
				buffer = args.buf,

				callback = function()
					write_markdown(args.buf)
					detach(args.buf)
				end,
			})
		end,
	})

	vim.api.nvim_create_user_command("CCExportSnapshot", function(opts)
		local ok, chat = pcall(function()
			return require("codecompanion").buf_get_chat(0)
		end)

		if not ok or not chat then
			vim.notify("[cc-auto-export] ここはチャットバッファではありません", vim.log.levels.ERROR)
			return
		end
		local ts = os.date("!%Y%m%dT%H%M%SZ")

		local base = ("%s_%s_%s.md"):format(
			slug(chat.title or "chat"),
			tostring(chat.id or vim.api.nvim_get_current_buf()),
			ts
		)
		local path = vim.fs.joinpath(export_dir(), base)
		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
		local content = {

			"---",
			M.tagline,
			"title: " .. (chat.title or "CodeCompanion Chat"),
			"created: " .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
			"---",

			"",
		}
		vim.list_extend(content, lines)
		vim.fn.writefile(content, path)

		vim.notify("[cc-auto-export] snapshot -> " .. path, vim.log.levels.INFO)
	end, { nargs = "?" })
end

return M
