#!/usr/bin/env bash
# Apply patches/*.patch, in name order, to the upstream checkout as commits
# (git am with 3-way merge). On a conflict, git am stops and leaves the
# checkout mid-apply so it can be resolved; see docs/updating-upstream.md.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../upstream.lock
source "$root/upstream.lock"

dest="${1:-$root/upstream}"

if [ ! -d "$dest/.git" ]; then
  echo "error: no upstream checkout at $dest; run scripts/fetch-upstream.sh first" >&2
  exit 1
fi

if [ "$(git -C "$dest" rev-parse HEAD)" != "$UPSTREAM_COMMIT" ]; then
  echo "error: $dest is not at the pinned commit; run scripts/fetch-upstream.sh first" >&2
  exit 1
fi

shopt -s nullglob
patches=("$root"/patches/*.patch)

if [ ${#patches[@]} -eq 0 ]; then
  echo "No patches to apply"
  exit 0
fi

# git am records a committer; the identity only lives inside ./upstream.
# A fixed identity and author dates keep the patched commits, and the build
# stamp that records them, identical on every run.
if ! git -C "$dest" \
    -c user.name="hermes-desktop-portable" \
    -c user.email="build@hermes-desktop-portable.invalid" \
    am -3 --keep-cr --whitespace=nowarn --committer-date-is-author-date "${patches[@]}"; then
  cat >&2 <<EOF

error: a patch did not apply to $UPSTREAM_TAG.
Resolve it inside $dest, then (see docs/updating-upstream.md):
  git -C "$dest" add <files>
  git -C "$dest" -c user.name=hermes-desktop-portable -c user.email=build@hermes-desktop-portable.invalid am --continue
  scripts/refresh-patches.sh
EOF
  exit 1
fi

echo "Applied ${#patches[@]} patch(es) on top of $UPSTREAM_TAG"
