-- The git index of the repo a file is in: the file as it was last staged.
-- The split and unified diffs of a buffer compare the buffer with it.

local M = {}

local function git(dir, args)
	local result = vim.system(vim.list_extend({ "git", "-C", dir }, args), { text = true }):wait()
	return result.code == 0 and result.stdout or nil
end

-- The file's lines as the index has them, or nil when the file isn't in a
-- git repo. A file git doesn't track yet has no lines there, so all of its
-- lines show as added.
function M.lines(path)
	local dir, name = vim.fs.dirname(path), vim.fs.basename(path)
	if not git(dir, { "rev-parse", "--is-inside-work-tree" }) then
		return nil
	end
	local out = git(dir, { "show", ":./" .. name })
	if not out then
		return {}
	end
	local lines = vim.split(out, "\n")
	if lines[#lines] == "" then
		table.remove(lines)
	end
	return lines
end

-- Call back when git writes the index of the file's repo, like after staging
-- or a commit. Git writes index.lock and renames it to index, so this watches
-- the folder the index is in. Returns a function that stops watching.
function M.watch(path, callback)
	local out = git(vim.fs.dirname(path), { "rev-parse", "--path-format=absolute", "--git-path", "index" })
	if not out then
		return function() end
	end
	local file = vim.trim(out)
	local watcher = vim.uv.new_fs_event()
	watcher:start(vim.fs.dirname(file), {}, function(err, name)
		if not err and name == vim.fs.basename(file) then
			vim.schedule(callback)
		end
	end)
	return function()
		watcher:close()
	end
end

return M
