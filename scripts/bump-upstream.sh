#!/usr/bin/env bash
# Point upstream.lock at a new upstream release tag, fetch it, apply the
# patches and re-export them against the new base.
#
#   scripts/bump-upstream.sh v0.23.0
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
lock="$root/upstream.lock"
# shellcheck source=../upstream.lock
source "$lock"

tag="${1:-}"
if [ -z "$tag" ]; then
  echo "usage: $0 <upstream-tag>   (for example v0.23.0)" >&2
  exit 2
fi
# Stable releases only: canary and other prerelease tags are not packaged,
# and neither are upstream's older date-based tags (v2026.9.24), whose
# "major" is a year.
if [[ ! "$tag" =~ ^v(0|[1-9][0-9]{0,2})\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: $tag is not a stable release tag (vX.Y.Z)" >&2
  exit 2
fi

# Annotated tags resolve through ^{}; lightweight tags have only the plain ref.
refs="$(git ls-remote "$UPSTREAM_REPO" "refs/tags/$tag" "refs/tags/$tag^{}")"
commit="$(awk -v t="refs/tags/$tag^{}" '$2 == t { print $1 }' <<<"$refs")"
if [ -z "$commit" ]; then
  commit="$(awk -v t="refs/tags/$tag" '$2 == t { print $1 }' <<<"$refs")"
fi
if [ -z "$commit" ]; then
  echo "error: tag $tag not found in $UPSTREAM_REPO" >&2
  exit 1
fi

previous="$UPSTREAM_TAG"
previous_commit="$UPSTREAM_COMMIT"
sed -i.bak \
  -e "s|^UPSTREAM_TAG=.*|UPSTREAM_TAG=\"$tag\"|" \
  -e "s|^UPSTREAM_COMMIT=.*|UPSTREAM_COMMIT=\"$commit\"|" \
  "$lock"
rm -f "$lock.bak"

echo "upstream.lock: $previous -> $tag ($commit)"

"$root/scripts/fetch-upstream.sh"
# The patches were made against the previous pin. The shallow checkout lacks
# those blobs, and git am -3 needs them for a three-way merge.
git -C "$root/upstream" fetch -q --depth 1 origin "$previous_commit"
"$root/scripts/apply-patches.sh"
# A patch may have applied only through the three-way fallback, which CI
# cannot repeat from a fresh shallow clone. Re-export so every patch applies
# exactly to the new base.
"$root/scripts/refresh-patches.sh"

echo "Now review git diff patches/ and commit upstream.lock and patches/ together."
