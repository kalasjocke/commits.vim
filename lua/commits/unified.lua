-- The unified diff: a buffer's added and changed lines highlighted, and the
-- lines it removed shown above them. The commit browser draws it for a commit's
-- file.

local M = {}

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

return M
