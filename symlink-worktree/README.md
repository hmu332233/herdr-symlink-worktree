# Symlink Worktree (herdr plugin)

When herdr creates a new git worktree, this plugin symlinks paths listed in the
main repo's `.herdr-worktree-links` into the new worktree.

Worktrees are separate directories, so gitignored items like `node_modules`,
`.env`, and build outputs are missing. Instead of refilling them by hand, this
plugin links them from the main repo automatically when the worktree is created.

## Requirements

- `jq` on `PATH` (macOS/Linux). If missing, the plugin skips quietly.
- herdr `>= 0.7.0`.

## Install (local)

```sh
herdr plugin link /path/to/symlink-worktree
```

## Configure a repo (opt-in)

Create `.herdr-worktree-links` in the **main repo root**. One path per line,
relative to the repo root. `#` comments and blank lines are ignored.

```text
# relative to main repo root, one per line
.env
.env.local
node_modules
```

The plugin acts only on repos that have this file. Repos without it are
untouched.

Keep the config out of git locally — paths like `.env` are personal, so don't
commit them as shared config:

```sh
echo ".herdr-worktree-links" >> .git/info/exclude
```

## Usage

Once configured, just create a worktree with herdr — the symlinks are made
automatically. Notes:

- Only **new** worktrees are linked; existing ones aren't updated retroactively.
- Existing files at the destination are never overwritten; absolute paths and
  `..` segments are rejected.
- Every run exits cleanly, so failures are quiet. If links don't appear, check
  the herdr plugin logs (and confirm `jq` is installed).
