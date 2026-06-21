#!/usr/bin/env bash
# Symlink Worktree plugin for herdr.
# On worktree.created, symlink paths listed in <main-repo>/.herdr-worktree-links
# from the main repo into the new worktree. All abnormal paths exit 0 quietly
# (stderr only) so the event log never shows Failed.

# 1. jq check
if ! command -v jq >/dev/null 2>&1; then
  echo "symlink-worktree: jq not found, skipping" >&2
  exit 0
fi

# 2. extract worktree path from event payload
WORKTREE=$(jq -r '.worktree.path // empty' <<<"$HERDR_PLUGIN_EVENT_JSON")
if [ -z "$WORKTREE" ] || [ ! -d "$WORKTREE" ]; then
  echo "symlink-worktree: no valid worktree path in event, skipping" >&2
  exit 0
fi

# 3. detect main repo root from inside the worktree
COMMON=$(git -C "$WORKTREE" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
if [ -z "$COMMON" ]; then
  echo "symlink-worktree: not a git repo: $WORKTREE" >&2
  exit 0
fi
SOURCE=$(dirname "$COMMON")
TOP=$(git -C "$WORKTREE" rev-parse --show-toplevel 2>/dev/null)
if [ "$SOURCE" = "$TOP" ]; then
  # main checkout, not a worktree -> no action
  exit 0
fi

# 4. read config
CONFIG="$SOURCE/.herdr-worktree-links"
if [ ! -f "$CONFIG" ]; then
  exit 0
fi

LINKS=()
while IFS= read -r line; do
  line="${line%%#*}"                 # strip comment
  line="${line#"${line%%[![:space:]]*}"}"  # ltrim
  line="${line%"${line##*[![:space:]]}"}"  # rtrim
  [ -z "$line" ] && continue
  LINKS+=("$line")
done <"$CONFIG"

if [ "${#LINKS[@]}" -eq 0 ]; then
  exit 0
fi

# 5. process each entry
linked=0
skipped=0
conflicts=()

for name in "${LINKS[@]}"; do
  # reject escape: absolute path or any .. segment
  case "$name" in
    /*)
      echo "symlink-worktree: path escapes repo: $name" >&2
      skipped=$((skipped + 1))
      continue
      ;;
  esac
  case "/$name/" in
    */../*)
      echo "symlink-worktree: path escapes repo: $name" >&2
      skipped=$((skipped + 1))
      continue
      ;;
  esac

  src="$SOURCE/$name"
  dest="$WORKTREE/$name"

  if [ ! -e "$src" ]; then
    echo "symlink-worktree: no source: $src" >&2
    skipped=$((skipped + 1))
    continue
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "symlink-worktree: exists: $dest" >&2
    skipped=$((skipped + 1))
    conflicts+=("$name")
    continue
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "linked: $dest -> $src"
  linked=$((linked + 1))
done

# 6. summary line
if [ "${#conflicts[@]}" -gt 0 ]; then
  echo "symlink-worktree: linked $linked, skipped $skipped (conflicts: ${conflicts[*]})"
else
  echo "symlink-worktree: linked $linked, skipped $skipped"
fi

exit 0
