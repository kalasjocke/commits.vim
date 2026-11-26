-- The unified diff: a buffer's added and changed lines highlighted, and the
-- lines it removed shown above them. The commit browser draws it for a commit's
-- file, and toggle() for a buffer's changes since HEAD.

local M = {}

local ns = vim.api.nvim_create_namespace("commits.unified")
local group = vim.api.nvim_create_augroup("commits.unified", { clear = true })

-- The buffer's lines. An empty buffer has no lines, not one empty line.
function M.lines(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	if #lines == 1 and lines[1] == "" then
		return {}
	end
	return lines
end

-- An empty file is an empty string, not one empty line, or an added file's
-- blank lines would match it and split its one hunk.
local function text(lines)
	return #lines > 0 and table.concat(lines, "\n") .. "\n" or ""
end

-- The hunks from the old lines to the new ones, as vim.text.diff's indices:
-- old start, old count, new start, new count.
function M.diff(old, new)
	return vim.text.diff(text(old), text(new), { result_type = "indices", algorithm = "histogram" })
end

-- The line a hunk's removed lines go at, and whether they go above it. They go
-- above the new lines, or below the line before them when nothing replaced
-- them. A deleted file has one empty line, and its hunk starts at 0, so its
-- removed lines go above that line.
function M.anchor(hunk)
	local _, _, new_start, new_count = unpack(hunk)
	return math.max(new_start, 1), new_count > 0 or new_start == 0
end

-- Where each hunk starts: the line, and the number of removed lines drawn
-- above it.
function M.starts(hunks)
	local starts = {}
	for _, hunk in ipairs(hunks) do
		local anchor, above = M.anchor(hunk)
		table.insert(starts, { line = anchor, above = above and hunk[2] or 0 })
	end
	return starts
end

-- The start after or before the line, wrapping around at the last and first.
function M.step(starts, line, direction)
	if direction > 0 then
		for _, start in ipairs(starts) do
			if start.line > line then
				return start
			end
		end
		return starts[1]
	end
	for i = #starts, 1, -1 do
		if starts[i].line < line then
			return starts[i]
		end
	end
	return starts[#starts]
end

-- Highlight the hunks' new lines in the buffer and put their old lines above
-- them, in the namespace.
function M.draw(buf, ns, old, hunks)
	local tab = string.rep(" ", vim.bo[buf].tabstop)
	local width = vim.o.columns
	for _, hunk in ipairs(hunks) do
		local old_start, old_count, new_start, new_count = unpack(hunk)
		local line_hl = old_count == 0 and "CommitsAddLine" or "CommitsChangeLine"
		for line = new_start, new_start + new_count - 1 do
			vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, { line_hl_group = line_hl })
		end
		local virt_lines = {}
		for line = old_start, old_start + old_count - 1 do
			local removed = old[line]:gsub("\t", tab)
			table.insert(
				virt_lines,
				{ { removed .. string.rep(" ", width - vim.fn.strdisplaywidth(removed)), "CommitsDeleteLine" } }
			)
		end
		if #virt_lines > 0 then
			local anchor, above = M.anchor(hunk)
			vim.api.nvim_buf_set_extmark(buf, ns, anchor - 1, 0, { virt_lines = virt_lines, virt_lines_above = above })
		end
	end
end

-- The buffers toggle() shows the changes of, each with HEAD's lines, the timer
-- that delays a redraw and the function that stops watching HEAD.
local showing = {}

-- Whether toggle() shows the buffer's changes.
function M.shown(buf)
	return showing[buf] ~= nil
end

local function redraw(buf)
	local view = showing[buf]
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	M.draw(buf, ns, view.head, M.diff(view.head, M.lines(buf)))
end

local function stop(buf)
	local view = showing[buf]
	showing[buf] = nil
	view.timer:close()
	view.unwatch()
	vim.api.nvim_clear_autocmds({ group = group, buffer = buf })
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	end
end

-- Show the current buffer's changes since HEAD as a unified diff, or stop
-- showing them. The diff follows edits as you make them, and HEAD when it
-- moves, like after a commit.
function M.toggle()
	local buf = vim.api.nvim_get_current_buf()
	if showing[buf] then
		return stop(buf)
	end
	local head = require("commits.head")
	local path = vim.api.nvim_buf_get_name(buf)
	local lines = vim.bo[buf].buftype == "" and path ~= "" and head.lines(path)
	if not lines then
		return vim.notify("Not a file in a git repo", vim.log.levels.WARN)
	end
	local view = { head = lines, timer = vim.uv.new_timer() }
	showing[buf] = view
	-- Redraw a moment after the last change, not on each key.
	local function later()
		view.timer:start(
			100,
			0,
			vim.schedule_wrap(function()
				if showing[buf] == view then
					redraw(buf)
				end
			end)
		)
	end
	view.unwatch = head.watch(path, function()
		if showing[buf] == view then
			view.head = head.lines(path) or {}
			later()
		end
	end)
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufReadPost" }, {
		group = group,
		buffer = buf,
		callback = later,
	})
	vim.api.nvim_create_autocmd("BufUnload", {
		group = group,
		buffer = buf,
		callback = function()
			stop(buf)
		end,
	})
	redraw(buf)
end

return M
