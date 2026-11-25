-- Color the split diff as GitHub does: the old version on the left with
-- removed lines in red, the new one on the right with added lines in green,
-- and an empty row with no line number across from a line only the other side
-- has.
--
-- Diff mode colors a line that only one side has the same on both sides, so
-- each window maps the diff colors to its own.
--
-- The commit browser's split diff uses style(). toggle(), which is
-- commits.split(), shows the current buffer's changes the same way, with the
-- index on the left.

local M = {}

local group = vim.api.nvim_create_augroup("commits.diffsplit", { clear = true })

-- Blend color a into color b by amount, from 0 to 1.
local function mix(a, b, amount)
	local out = 0
	for shift = 16, 0, -8 do
		local x, y = bit.band(bit.rshift(a, shift), 0xff), bit.band(bit.rshift(b, shift), 0xff)
		out = out + bit.lshift(math.floor(x * amount + y * (1 - amount) + 0.5), shift)
	end
	return out
end

-- Backgrounds only, so syntax colors show through: the theme's Added and
-- Removed colors faint for a line, and stronger for the changed text in it.
local function set_highlights()
	local function fg(name, default)
		return vim.api.nvim_get_hl(0, { name = name, link = false }).fg or default
	end
	local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg or 0
	local add, remove = fg("Added", 0x3fb950), fg("Removed", 0xf85149)
	vim.api.nvim_set_hl(0, "CommitsSplitAdd", { bg = mix(add, bg, 0.15) })
	vim.api.nvim_set_hl(0, "CommitsSplitAddText", { bg = mix(add, bg, 0.35) })
	vim.api.nvim_set_hl(0, "CommitsSplitRemove", { bg = mix(remove, bg, 0.15) })
	vim.api.nvim_set_hl(0, "CommitsSplitRemoveText", { bg = mix(remove, bg, 0.35) })
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })

-- Diff mode's colors on each side. DiffDelete is the empty row across from a
-- line the other side has.
local sides = {
	left = "DiffAdd:CommitsSplitRemove,DiffChange:CommitsSplitRemove,DiffText:CommitsSplitRemoveText,"
		.. "DiffTextAdd:CommitsSplitRemoveText,DiffDelete:Normal",
	right = "DiffAdd:CommitsSplitAdd,DiffChange:CommitsSplitAdd,DiffText:CommitsSplitAddText,"
		.. "DiffTextAdd:CommitsSplitAddText,DiffDelete:Normal",
}

-- Set the window's own colors and an empty fill for its side, leaving the
-- values new windows get alone.
local function style(win, side)
	local fillchars = vim.api.nvim_get_option_value("fillchars", { win = win })
	-- Replace an earlier diff fill, as the window may have this style already.
	local fill = vim.tbl_filter(function(item)
		return not vim.startswith(item, "diff:")
	end, vim.split(fillchars, ",", { trimempty = true }))
	table.insert(fill, "diff: ")
	vim.api.nvim_set_option_value("winhighlight", sides[side], { scope = "local", win = win })
	vim.api.nvim_set_option_value("fillchars", table.concat(fill, ","), { scope = "local", win = win })
end

-- Color two windows in diff mode, with the old version on the left and the
-- new one on the right.
function M.style(left, right)
	style(left, "left")
	style(right, "right")
end

-- The window in the current tab that shows the index for toggle().
local function index_window()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.b[vim.api.nvim_win_get_buf(win)].commits_index then
			return win
		end
	end
end

-- Show the current buffer's changes as a split diff, with the index on the
-- left, or close the split when it's open. Edits to the buffer show as you
-- make them. Staging doesn't, until the split opens again.
function M.toggle()
	local left = index_window()
	if left then
		return vim.api.nvim_win_close(left, false)
	end
	local right, file = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(file)
	local lines = vim.bo[file].buftype == "" and path ~= "" and require("commits.index").lines(path)
	if not lines then
		return vim.notify("Not a file in a git repo", vim.log.levels.WARN)
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = vim.bo[file].filetype
	vim.b[buf].commits_index = true
	left = vim.api.nvim_open_win(buf, false, { split = "left", win = right })
	vim.wo[left].winbar = "%#Identifier#index%* " .. vim.fn.fnamemodify(path, ":~:.")
	local saved = {}
	for _, name in ipairs({ "winhighlight", "fillchars" }) do
		saved[name] = vim.api.nvim_get_option_value(name, { win = right })
	end
	M.style(left, right)
	for _, win in ipairs({ left, right }) do
		vim.api.nvim_win_call(win, function()
			vim.cmd("diffthis")
		end)
	end
	-- However the left side closes, turn diff mode off on the right and put
	-- its colors back.
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		pattern = tostring(left),
		once = true,
		callback = function()
			if not vim.api.nvim_win_is_valid(right) then
				return
			end
			vim.api.nvim_win_call(right, function()
				vim.cmd("diffoff")
			end)
			for name, value in pairs(saved) do
				vim.api.nvim_set_option_value(name, value, { scope = "local", win = right })
			end
		end,
	})
end

return M
