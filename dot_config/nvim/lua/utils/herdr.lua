local M = {}

local function notify(message, level)
	vim.notify("herdr: " .. message, level or vim.log.levels.INFO)
end

---@param args string[]
---@param callback fun(decoded: table|nil)
local function herdr_json(args, callback)
	local command = { "herdr" }
	vim.list_extend(command, args)

	vim.system(command, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				notify(vim.trim(result.stderr or "command failed"), vim.log.levels.ERROR)
				callback(nil)
				return
			end

			local ok, decoded = pcall(vim.json.decode, result.stdout)
			if not ok or type(decoded) ~= "table" then
				notify("failed to parse command output", vim.log.levels.ERROR)
				callback(nil)
				return
			end
			callback(decoded)
		end)
	end)
end

---@param path string
---@param cwd string|nil
---@return string
local function relative_path(path, cwd)
	if not cwd or cwd == "" then
		return path
	end

	local prefix = vim.fs.normalize(cwd):gsub("/+$", "") .. "/"
	local normalized = vim.fs.normalize(path)
	if normalized:sub(1, #prefix) == prefix then
		return normalized:sub(#prefix + 1)
	end
	return normalized
end

---@param callback fun(agent: table)
local function select_agent(callback)
	if vim.env.HERDR_ENV ~= "1" then
		notify("Neovim is not running in a herdr pane", vim.log.levels.WARN)
		return
	end

	local tab_id = vim.env.HERDR_TAB_ID
	if not tab_id or tab_id == "" then
		notify("HERDR_TAB_ID is not set", vim.log.levels.ERROR)
		return
	end

	herdr_json({ "agent", "list" }, function(decoded)
		if not decoded then
			return
		end

		local agents = {}
		for _, agent in ipairs(((decoded.result or {}).agents or {})) do
			if agent.tab_id == tab_id and agent.pane_id ~= vim.env.HERDR_PANE_ID then
				agents[#agents + 1] = agent
			end
		end

		if #agents == 0 then
			notify("no coding agent found in the current tab", vim.log.levels.WARN)
			return
		end
		if #agents == 1 then
			callback(agents[1])
			return
		end

		local cwd = vim.uv.cwd()
		table.sort(agents, function(a, b)
			local a_same = (a.foreground_cwd or a.cwd) == cwd
			local b_same = (b.foreground_cwd or b.cwd) == cwd
			if a_same ~= b_same then
				return a_same
			end
			return (a.display_agent or a.agent or a.pane_id) < (b.display_agent or b.agent or b.pane_id)
		end)

		vim.ui.select(agents, {
			prompt = "Send context to agent",
			format_item = function(agent)
				return string.format(
					"%s [%s] — %s",
					agent.display_agent or agent.agent or agent.pane_id,
					agent.agent_status or "unknown",
					agent.foreground_cwd or agent.cwd or "?"
				)
			end,
		}, function(agent)
			if agent then
				callback(agent)
			end
		end)
	end)
end

---@param range integer[]|nil
local function send(range)
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		notify("current buffer has no file name", vim.log.levels.WARN)
		return
	end
	path = vim.fn.fnamemodify(path, ":p")

	select_agent(function(agent)
		local payload = "@" .. relative_path(path, agent.foreground_cwd or agent.cwd)
		if range then
			local first, last = range[1], range[2]
			if first > last then
				first, last = last, first
			end
			payload = payload .. "#L" .. first
			if first ~= last then
				payload = payload .. "-L" .. last
			end
		end

		vim.system({ "herdr", "pane", "send-text", agent.pane_id, payload .. " " }, { text = true }, function(result)
			vim.schedule(function()
				if result.code ~= 0 then
					notify("send-text failed: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
					return
				end
				vim.system({ "herdr", "agent", "focus", agent.pane_id }, { text = true }, function(focus_result)
					if focus_result.code ~= 0 then
						vim.schedule(function()
							notify("context sent, but focus failed: " .. vim.trim(focus_result.stderr or ""), vim.log.levels.WARN)
						end)
					end
				end)
			end)
		end)
	end)
end

function M.send_file()
	send(nil)
end

function M.send_selection()
	send({ vim.fn.line("v"), vim.fn.line(".") })
end

return M
