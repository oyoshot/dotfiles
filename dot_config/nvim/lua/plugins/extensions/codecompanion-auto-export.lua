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
	s = (s or "chat"):gsub('[/\\:?*"<>|]', " "):gsub("%s+", "-")
	if s == "" then
		s = "chat"
	end
	return s
end

local function write_markdown(bufnr)
	local ok, cc = pcall(require, "codecompanion")
	if not ok then
		return
	end
	local chat = cc.buf_get_chat(bufnr)
	if not chat then
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

	local out = {}
	vim.list_extend(out, header)
	vim.list_extend(out, lines)

	local name = ("%s_%s.md"):format(slug(chat.title or "chat"), tostring(chat.id or bufnr))
	local path = vim.fs.joinpath(export_dir(), name)
	vim.fn.writefile(out, path)
end

function M.setup()
	local main = vim.api.nvim_create_augroup("CCAutoExportMain", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = main,
		pattern = { "codecompanion", "codecompanion-chat" },
		callback = function(args)
			local bufnr = args.buf
			local g = vim.api.nvim_create_augroup("CCAutoExport_" .. bufnr, { clear = true })
			local timer_id
			local function schedule()
				if timer_id then
					vim.fn.timer_stop(timer_id)
				end
				timer_id = vim.fn.timer_start(M.debounce_ms, function()
					vim.schedule(function()
						if vim.api.nvim_buf_is_loaded(bufnr) then
							write_markdown(bufnr)
						end
					end)
				end)
			end

			write_markdown(bufnr)

			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
				group = g,
				buffer = bufnr,
				callback = schedule,
			})

			vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout", "BufUnload" }, {
				group = g,
				buffer = bufnr,
				callback = function()
					write_markdown(bufnr)
					if timer_id then
						vim.fn.timer_stop(timer_id)
					end
				end,
			})
		end,
	})
end

return M
