-- The files with changes since HEAD in a repo, as git status lists them:
-- staged, unstaged and untracked. Outside a browser, commits.next_file() and
-- commits.prev_file() go through them.

local M = {}

-- The changed files' paths, relative to the repo's root and sorted. Deleted
-- files aren't there, as there's nothing to open.
function M.files(root)
	local cmd = { "git", "-C", root, "status", "--porcelain", "-z", "--no-renames", "--untracked-files=all" }
	local result = vim.system(cmd, { text = true }):wait()
	if result.code ~= 0 then
		return {}
	end
	local files = {}
	-- Each entry is the two status letters, a space and the path.
	for _, entry in ipairs(vim.split(result.stdout, "\0", { plain = true, trimempty = true })) do
		local path = entry:sub(4)
		local stat = vim.uv.fs_stat(root .. "/" .. path)
		if stat and stat.type == "file" then
			table.insert(files, path)
		end
	end
	table.sort(files)
	return files
end

-- The file after or before the path, wrapping around at the last and first. A
-- path that isn't one of the files goes where it sorts, and no path goes
-- before the first.
function M.step(files, path, direction)
	if direction > 0 then
		for _, file in ipairs(files) do
			if not path or file > path then
				return file
			end
		end
		return files[1]
	end
	for i = #files, 1, -1 do
		if not path or files[i] < path then
			return files[i]
		end
	end
	return files[#files]
end

return M
