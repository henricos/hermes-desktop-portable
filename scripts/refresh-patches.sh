#!/usr/bin/env bash
# Export the commits on top of the pinned upstream commit in ./upstream back
# into patches/, replacing the existing *.patch files.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../upstream.lock
source "$root/upstream.lock"

dest="${1:-$root/upstream}"

if [ ! -d "$dest/.git" ]; then
  echo "error: no upstream checkout at $dest" >&2
  exit 1
fi

# Exporting mid-operation would write a partial stack and delete the rest.
if [ -d "$dest/.git/rebase-apply" ] || [ -d "$dest/.git/rebase-merge" ]; then
  echo "error: git am or rebase is still in progress in $dest; finish or abort it first" >&2
  exit 1
fi

if ! git -C "$dest" merge-base --is-ancestor "$UPSTREAM_COMMIT" HEAD; then
  echo "error: HEAD in $dest does not descend from the pinned commit $UPSTREAM_COMMIT" >&2
  exit 1
fi

count="$(git -C "$dest" rev-list --count "$UPSTREAM_COMMIT"..HEAD)"
if [ "$count" -eq 0 ]; then
  echo "error: no commits on top of $UPSTREAM_TAG; refusing to empty patches/" >&2
  exit 1
fi

rm -f "$root"/patches/*.patch
# --zero-commit, --no-signature, --full-index and --no-numbered keep each file
# stable across re-exports, whatever the clone's object count or the number
# of patches.
git -C "$dest" format-patch -q --zero-commit --no-signature --no-stat --full-index --no-numbered \
  -o "$root/patches" "$UPSTREAM_COMMIT"..HEAD

echo "Exported $count patch(es) to patches/"
