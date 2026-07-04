# Symlink Worktree

Symlink Worktree is a [herdr](https://herdr.dev) plugin that shares selected
files and directories from your main Git checkout with every new herdr
worktree.

It is useful for local, gitignored state that you do not want to recreate for
each worktree, such as `.env` files, deployment config, build caches, and other
development-only artifacts.

```text
new-worktree/.env          -> main-checkout/.env
new-worktree/.turbo        -> main-checkout/.turbo
```

## Quick Start

1. Install or link the plugin.

   ```sh
   herdr plugin link /path/to/symlink-worktree
   ```

   From GitHub:

   ```sh
   herdr plugin install owner/symlink-worktree
   ```

2. In the main checkout of a repository, create `.herdr-worktree-links`.

   ```text
   .env
   .env.local
   .turbo
   .next/cache
   .vercel
   ```

3. Create worktrees with herdr as usual.

   When herdr emits `worktree.created`, the plugin reads
   `.herdr-worktree-links` from the main checkout and creates the same paths as
   symlinks in the new worktree.

Repositories without `.herdr-worktree-links` are ignored.

## Configuration

`.herdr-worktree-links` uses one repository-relative path per line. Blank lines
are ignored, and `#` starts a comment.

```text
# Share local environment and development caches with new worktrees.
.env
.env.local
.turbo
.next/cache
.vercel
```

Keep this file local unless your team intentionally wants to share the same
paths:

```sh
echo ".herdr-worktree-links" >> .git/info/exclude
```

## Behavior

- Runs on herdr's `worktree.created` event.
- Only processes new worktrees; existing worktrees are not changed.
- Never overwrites an existing destination file, directory, or symlink.
- Skips missing source paths.
- Rejects absolute paths and paths containing `..`.
- Creates parent directories before creating a symlink.
- Exits successfully on skips and validation failures so the herdr event is not
  marked as failed.

## Requirements

- herdr `>= 0.7.0`
- macOS or Linux
- `jq` on `PATH`
- Git worktrees created through herdr

If `jq` is missing, the plugin skips the run without failing the herdr event.

## Troubleshooting

If links are not created:

1. Check that the plugin is installed and enabled.

   ```sh
   herdr plugin list
   ```

2. Check that `jq` is installed.

   ```sh
   jq --version
   ```

3. Check that `.herdr-worktree-links` exists in the main checkout, not only in
   the new worktree.

4. Check the plugin logs.

   ```sh
   herdr plugin log list --plugin dev.minung.symlink-worktree
   ```

## Security

This plugin runs as your local user and creates symlinks to paths from your main
checkout. Review `.herdr-worktree-links` before use, especially in repositories
that contain secrets or large generated directories.

## License

TBD. Add a `LICENSE` file before publishing this plugin as open source.
