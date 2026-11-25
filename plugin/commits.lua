-- :Commits takes git log arguments, like :Commits main..HEAD --author=Joakim.
-- The module loads the first time the command runs.
if vim.g.loaded_commits then
	return
end
vim.g.loaded_commits = true

vim.api.nvim_create_user_command("Commits", function(cmd)
	require("commits").open(cmd.fargs)
end, { nargs = "*", desc = "Go through the commits git log lists" })
