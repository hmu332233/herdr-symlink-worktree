# Symlink Worktree (herdr plugin)

When a new git worktree is created, this plugin symlinks paths listed in the
main repo's `.herdr-worktree-links` into the new worktree.

Worktrees are separate directories, so gitignored items like `node_modules`,
`.env`, and build outputs are missing. Instead of refilling them by hand, this
plugin links them from the main repo automatically when the worktree is created.

## Requirements

- `jq` on `PATH` (macOS/Linux). If missing, the plugin skips quietly.
- herdr `>= 0.7.0`.

## Install (local)

```sh
herdr plugin link /path/to/my-herdr-symlink-worktree
```

Local-only. Not distributed via GitHub install.

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

Keep the config out of git locally (don't commit it):

```sh
echo ".herdr-worktree-links" >> .git/info/exclude
```

## Behavior

For each entry in `.herdr-worktree-links`:

- `src = <main-repo>/<entry>`, `dest = <worktree>/<entry>`.
- Source missing -> skip (stderr).
- Dest already exists (real file or symlink) -> skip + counted as conflict
  (stderr). Existing files are never overwritten.
- Otherwise -> `mkdir -p` the parent, then `ln -s src dest`.

Nested paths are allowed (parent dirs auto-created). Absolute paths and any
`..` segment are rejected as repo escapes.

### Principles

- **Always exits 0.** Conflicts and errors log to stderr only — the herdr event
  log is never marked Failed.
- **Idempotent.** Existing dest is skipped, so re-running on the same worktree
  is safe (duplicate entries skip on the second pass).
- **Opt-in.** No config file -> no action.

## Files

```
my-herdr-symlink-worktree/
  herdr-plugin.toml   # plugin manifest, hooks worktree.created
  link.sh             # the hook script
  README.md           # English
  README.ko.md        # Korean
```

## Verify (manual)

1. `herdr plugin link` this directory.
2. In a test repo, create `.herdr-worktree-links` and add it to
   `.git/info/exclude`. Confirm the listed sources actually exist.
3. Create a worktree.
4. `herdr plugin log list --plugin dev.minung.symlink-worktree` — check the run log
   and summary line.
5. `ls -la <worktree>` — confirm the symlinks.
6. Check cases: conflict (dest exists), missing source, repo without the config
   file (no action), nested path.

## Out of scope (for now)

- Manual `relink` action (events only).
- GitHub distribution / Windows support.
- Stale symlink detection / self-healing.
- Global defaults via a config dir.
