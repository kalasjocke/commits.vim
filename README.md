# commits.vim

A Neovim plugin to read code changes faster, one commit at a time.

The plugin opens a tab with a list of commits at the bottom, one per line, with each commit's hash, subject, author and date, and the number of files and lines it changed. A commit opens to show its files, each with its status and line counts. The list reloads when a ref changes, like after a commit, a rebase or a fetch.

Above the list is the diff of the selected file. It's unified, with removed lines shown above the new ones, or split, with the old file on the left. The file is the real one, checked out in a worktree of the repo, so language servers work in it.

In the browser:

| Key          | Action                                               |
| ------------ | ---------------------------------------------------- |
| `]c` `[c`    | Next or previous commit                              |
| `]f` `[f`    | Next or previous file of the commit                  |
| `]h` `[h`    | Next or previous hunk in the diff                    |
| `<CR>` `o`   | Show or hide a commit's files, or open a file's diff |
| `M`          | The full commit message                              |
| `O`          | The commit on its web host, like GitHub              |
| `P`          | The commit's pull request                            |
| `y`          | Copy the commit's hash, or hash:path on a file       |
| `<leader>gd` | Switch to the unified diff                           |
| `<leader>gD` | Switch to the split diff                             |
| `q`          | Close the browser                                    |

## Requirements

- Neovim 0.11 or later.
- git.
- The GitHub CLI, `gh`, for `commits.pull_request()`, which opens a commit's pull request. Optional.

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

`:Commits` takes `git log` arguments, like `:Commits main..HEAD --author=Joakim`. The plugin sets no global keys. Map the functions it has for common lists and for your uncommitted changes:

```lua
local commits = require("commits")
commits.setup({ diff = "split" }) -- optional
vim.keymap.set("n", "<leader>gl", commits.log) -- the last 100 commits
vim.keymap.set("n", "<leader>gh", commits.file) -- the commits that changed this file
vim.keymap.set("x", "<leader>gh", commits.lines) -- or these lines
vim.keymap.set("n", "<leader>gm", commits.branch) -- this branch's commits, oldest first
vim.keymap.set("n", "<leader>gd", commits.unified) -- this buffer's changes as a unified diff
vim.keymap.set("n", "<leader>gD", commits.split) -- or as a split diff
vim.keymap.set("n", "]f", commits.next_file) -- the next file git status lists
vim.keymap.set("n", "[f", commits.prev_file)
vim.keymap.set("n", "]h", commits.next_hunk) -- the next hunk of this buffer's changes
vim.keymap.set("n", "[h", commits.prev_hunk)
```

Each of the browser's keys calls a function, like `commits.next_commit`, so you can set your mapping with `on_attach`:

```lua
commits.setup({
  on_attach = function(buf, kind) -- kind is "list" or "diff"
    local opts = { buffer = buf, nowait = true }
    vim.keymap.set("n", "M", commits.message, opts)
    -- ...
  end,
})
```

See `:help commits` for all the keys and functions, the options and the colors.

## License

MIT
