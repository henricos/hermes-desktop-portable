#!/usr/bin/env bash
# Fetch the pinned upstream commit into ./upstream (shallow, single commit),
# discarding any local state there, including applied patches.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../upstream.lock
source "$root/upstream.lock"

dest="${1:-$root/upstream}"

if [ -d "$dest/.git" ]; then
  echo "Reusing existing checkout at $dest"
  # Drop any interrupted git am or rebase. Removing the state directly works
  # even without a Git identity, which `git am --abort` would need.
  rm -rf "$dest/.git/rebase-apply" "$dest/.git/rebase-merge"
else
  git init -q "$dest"
  git -C "$dest" remote add origin "$UPSTREAM_REPO"
fi

git -C "$dest" fetch -q --depth 1 origin "$UPSTREAM_COMMIT"
git -C "$dest" checkout -q --force --detach "$UPSTREAM_COMMIT"
# Keep node_modules: reinstalling the monorepo takes minutes, and npm ci
# replaces it from the lockfile anyway.
git -C "$dest" clean -q -fdx -e node_modules

actual="$(git -C "$dest" rev-parse HEAD)"
if [ "$actual" != "$UPSTREAM_COMMIT" ]; then
  echo "error: expected $UPSTREAM_COMMIT, got $actual" >&2
  exit 1
fi

echo "Upstream $UPSTREAM_TAG ($UPSTREAM_COMMIT) checked out at $dest"
