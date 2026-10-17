local M = {}

--- Asynchronously searches for a root directory containing a specific pattern.
-- This function searches for a file or directory matching any of the given patterns,
-- starting from the specified path and moving up the directory tree. The search
-- stops when a match is found or the maximum search depth is reached.
--
-- @param patterns table A list of file or directory patterns to search for (e.g., `{"init.lua", ".git"}`).
-- @param startpath string The starting directory for the search.
-- @param max_depth number (optional) The maximum depth to search upwards in the directory tree. Default is 5.
-- @return function Returns an asynchronous function that calls the provided callback with
--                  the absolute path to the matching file/directory if found, or `nil` otherwise.
M.async_find_root = function(patterns, startpath, max_depth)
	local async = require("plenary.async")
	local path = require("plenary.path")
	max_depth = max_depth or 5
	return async.wrap(function(callback)
		local directory = startpath
		local depth = 0

		while directory and depth < max_depth do
			for _, pattern in ipairs(patterns) do
				local file_path = path:new(directory, pattern)
				if file_path:exists() then
					callback(file_path:absolute())
					return
				end
			end

			local parent = path:new(directory):parent():absolute()
			if parent == directory then
				break
			end

			directory = parent
			depth = depth + 1
		end

		callback(nil)
	end, 1)
end

return M
