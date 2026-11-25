-- :checkhealth commits

local M = {}

function M.check()
	vim.health.start("commits")
	if vim.fn.has("nvim-0.11") == 1 then
		vim.health.ok("Neovim 0.11 or later")
	else
		vim.health.error("Needs Neovim 0.11 or later")
	end
	if vim.fn.executable("git") == 1 then
		vim.health.ok("git is installed")
	else
		vim.health.error("git is not installed")
	end
	if vim.fn.executable("gh") == 1 then
		vim.health.ok("gh is installed, for P")
	else
		vim.health.warn("gh is not installed, so P can't find a commit's pull request")
	end
end

return M
