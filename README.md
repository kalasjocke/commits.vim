# commits.vim

Go through git commits in Neovim with a diff of each changed file.

A browser opens in a new tab with the list of commits at the bottom and a diff above it. Move by commit with `]c` and `[c`, by file with `]f` and `[f`, and by hunk with `]h` and `[h`. The diff is unified, with removed lines shown above the new ones, or split, with the old file on the left. The file is the real one, checked out in a worktree of the repo, so language servers work in it.

## Requirements

- Neovim 0.11 or later.
- git.
- The GitHub CLI, `gh`, for `P`, which opens a commit's pull request. Optional.
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) for the unified diff's colors. Optional. Without it the diff uses the diff mode colors.

Run `:checkhealth commits` to check them.

## Install

With `vim.pack`:

```lua
vim.pack.add({ "https://github.com/kalasjocke/commits.vim" })
```

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'kalasjocke/commits.vim'
```

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "kalasjocke/commits.vim" }
```

## Usage

`:Commits` takes `git log` arguments, like `:Commits main..HEAD --author=Joakim`. The plugin sets no global keys. Map the functions it has for common lists:

```lua
local commits = require("commits")
commits.setup({ diff = "split" }) -- optional
vim.keymap.set("n", "<leader>gl", commits.log) -- the last 100 commits
vim.keymap.set("n", "<leader>gh", commits.file) -- the commits that changed this file
vim.keymap.set("x", "<leader>gh", commits.lines) -- or these lines
vim.keymap.set("n", "<leader>gm", commits.branch) -- this branch's commits, oldest first
vim.keymap.set("n", "<leader>gd", commits.unified) -- this buffer's changes as a unified diff
vim.keymap.set("n", "<leader>gD", commits.split) -- or as a split diff
```

`commits.unified` and `commits.split` show the current buffer's uncommitted changes the same way as the browser's diffs, compared with the index. Pressing the key again hides them.

See `:help commits` for the keys in the browser, the options and the colors.

## License

MIT
