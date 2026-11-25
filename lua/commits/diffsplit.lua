-- Color the split diff as GitHub does: the old version on the left with
-- removed lines in red, the new one on the right with added lines in green,
-- and an empty row with no line number across from a line only the other side
-- has.
--
-- Diff mode colors a line that only one side has the same on both sides, so
-- each window maps the diff colors to its own.

local M = {}

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
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

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

return M
