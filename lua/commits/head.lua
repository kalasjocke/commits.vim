-- The last commit of the repo a file is in, HEAD. The split and unified diffs
-- of a buffer compare the buffer with the file as HEAD has it.

local M = {}

local function git(dir, args)
	local result = vim.system(vim.list_extend({ "git", "-C", dir }, args), { text = true }):wait()
	return result.code == 0 and result.stdout or nil
end

-- The file's lines as HEAD has them, or nil when the file isn't in a git repo.
-- A file HEAD doesn't have, like a new one, has no lines there, so all of its
-- lines show as added.
function M.lines(path)
	local dir, name = vim.fs.dirname(path), vim.fs.basename(path)
	if not git(dir, { "rev-parse", "--is-inside-work-tree" }) then
		return nil
	end
	local out = git(dir, { "show", "HEAD:./" .. name })
	if not out then
		return {}
	end
	local lines = vim.split(out, "\n")
	if lines[#lines] == "" then
		table.remove(lines)
	end
	return lines
end

-- Call back when git writes a file in the git dir of the file's worktree, as
-- it does when HEAD moves: HEAD after a checkout, ORIG_HEAD after a reset and
-- the index after a commit. Git writes each through a .lock file it renames.
-- Returns a function that stops watching.
function M.watch(path, callback)
	local out = git(vim.fs.dirname(path), { "rev-parse", "--absolute-git-dir" })
	if not out then
		return function() end
	end
	local watcher = vim.uv.new_fs_event()
	watcher:start(vim.trim(out), {}, function(err, name)
		if not err and name and not name:match("%.lock$") then
			vim.schedule(callback)
		end
	end)
	return function()
		watcher:close()
	end
end

return M
