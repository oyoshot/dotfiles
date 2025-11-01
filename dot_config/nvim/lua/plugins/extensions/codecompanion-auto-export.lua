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

local function clean_title(t)
	if not t or t == "" then
		return "Chat"
	end

	t = t:gsub("```[%z\1-\255]-```", " ")
	t = t:gsub("`([^`]*)`", "%1")
	t = t:gsub("\\[rnt]", " ")
	t = t:gsub("[%c]", " ")
	t = t:gsub("^%s*#+%s*", "")
	t = t:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if t == "" then
		t = "Chat"
	end
	return t
end

local function sanitize_title_for_filename(t)
	t = clean_title(t)
	t = t:gsub("[%[%]()%{%}%+~=;:,.!%?&%^#@$/\\:_%*\"'<>|`]", " ")
	t = t:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	t = t:gsub("[%.%s]+$", "")
	if #t > 80 then
		t = t:sub(1, 80):gsub("%s+$", "")
	end
	if t == "" then
		t = "Chat"
	end
	return t
end

local function short_id(chat, bufnr)
	local id = tostring(chat.id or bufnr):gsub("%W", "")
	if #id >= 6 then
		return id:sub(-6)
	end
	return string.format("%06s", id)
end

local function title_from_first_user(chat)
	local msgs = (chat and chat.messages) or {}
	for _, m in ipairs(msgs) do
		if m.role == "user" and type(m.content) == "string" and #m.content > 0 then
			return clean_title(m.content)
		end
	end
	return nil
end

local function resolve_title(chat, bufnr)
	local t = chat and chat.title

	if t and not t:match("^chat%-%d+$") then
		return t
	end
	local inferred = title_from_first_user(chat)
	if inferred and inferred ~= "" then
		return inferred
	end
	return ("Chat %d"):format(bufnr)
end

local function make_base(chat, bufnr)
	local date = os.date("!%Y-%m-%d")
	local title = sanitize_title_for_filename(resolve_title(chat, bufnr))
	return string.format("%s-%s@%s", date, title, short_id(chat, bufnr))
end

local function uniquify_path(dir, base)
	local path = vim.fs.joinpath(dir, base .. ".md")
	if vim.fn.filereadable(path) == 0 then
		return path
	end
	local n = 2
	while true do
		local p = vim.fs.joinpath(dir, string.format("%s-%d.md", base, n))
		if vim.fn.filereadable(p) == 0 then
			return p
		end
		n = n + 1
		if n > 999 then
			return vim.fs.joinpath(dir, string.format("%s-%d.md", base, vim.loop.hrtime()))
		end
	end
end

local function stable_path(chat, bufnr)
	local dir = export_dir()
	local base = make_base(chat, bufnr)
	return uniquify_path(dir, base)
end

local function maybe_rename_file(bufnr, chat, current_path)
	local dir = export_dir()
	local expected_base = make_base(chat, bufnr)

	local current_base = vim.fn.fnamemodify(current_path, ":t:r")
	if current_base == expected_base or current_base:match("^" .. vim.pesc(expected_base) .. "%-%d+$") then
		return current_path
	end

	local target = uniquify_path(dir, expected_base)
	local ok = os.rename(current_path, target)
	return ok and target or target
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

	if not vim.b[bufnr].cc_auto_export_path then
		vim.b[bufnr].cc_auto_export_path = stable_path(chat, bufnr)
	else
		vim.b[bufnr].cc_auto_export_path = maybe_rename_file(bufnr, chat, vim.b[bufnr].cc_auto_export_path)
	end
	local path = vim.b[bufnr].cc_auto_export_path

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local header = {
		"---",
		M.tagline,
		"title: " .. resolve_title(chat, bufnr),
		"updated: " .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
		"---",
		"",
	}

	local out = {}
	vim.list_extend(out, header)
	vim.list_extend(out, lines)
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
