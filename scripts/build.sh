#!/usr/bin/env bash
# Build the Windows x64 portable ZIP from the pinned upstream plus patches/.
# This is the single build entry point: the GitHub Actions workflow runs it
# as is. It must run on Windows (Git Bash), with the Node and pnpm versions
# upstream pins; see docs/build-local.md.
#
#   scripts/build.sh [--version v0.23.1-r1]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../upstream.lock
source "$root/upstream.lock"

version="${UPSTREAM_TAG}-dev"
while [ $# -gt 0 ]; do
  case "$1" in
    --version) version="${2:?--version needs a value}"; shift 2 ;;
    *) echo "error: unknown argument $1" >&2; exit 2 ;;
  esac
done

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *)
    echo "error: the Windows package must be built on Windows (see docs/build-local.md)." >&2
    echo "Build the package on GitHub Actions instead; patch work (fetch, apply, refresh) runs here." >&2
    exit 1
    ;;
esac

upstream="$root/upstream"
app="$upstream/apps/desktop"
out="$root/dist"
artifact="HermesPortable-${version}.zip"

echo "==> Upstream $UPSTREAM_TAG + patches"
"$root/scripts/fetch-upstream.sh" "$upstream"
"$root/scripts/apply-patches.sh" "$upstream"

wanted_node="$(tr -d '[:space:]v' < "$upstream/.nvmrc")"
actual_node="$(node --version | tr -d 'v' | cut -d. -f1)"
if [ "${wanted_node%%.*}" != "$actual_node" ]; then
  echo "warning: upstream pins Node $wanted_node, running Node $actual_node" >&2
fi
# Upstream refuses any pnpm but the one pm/lock.json pins (root preinstall).
wanted_pnpm="$(cd "$upstream" && node -p 'require("./pm/lock.json").packages.pnpm.version')"
actual_pnpm="$(pnpm --version 2>/dev/null || echo none)"
if [ "$wanted_pnpm" != "$actual_pnpm" ]; then
  echo "error: upstream pins pnpm $wanted_pnpm, found $actual_pnpm (npm install --global pnpm@$wanted_pnpm)" >&2
  exit 1
fi

echo "==> Installing dependencies"
(cd "$upstream" && pnpm install --frozen-lockfile)
# Electron's install no longer fetches its binary; upstream prepares it in an
# explicit step before building, as its own CI does.
(cd "$upstream" && node scripts/build/electron-runtime.mjs --source .)

echo "==> Building apps/desktop (variant: light)"
export HERMES_DESKTOP_VARIANT=light
# These switch upstream's build into release, channel or signing modes, which
# need tags, Python or credentials.
unset HERMES_PAYLOAD_TAG HERMES_BUILD_COMMIT _HERMES_CHANNEL_REQUEST_JSON \
  AZURE_SIGN_ENDPOINT AZURE_CLIENT_ID CSC_LINK
# The build stamp takes its commit from GITHUB_SHA, or else from the checkout's
# HEAD, which is the patched commit that exists only here. Record the pinned
# upstream commit and tag instead, so About links to a real upstream commit.
# On CI, GITHUB_SHA would otherwise be this repository's commit.
(cd "$app" && GITHUB_SHA="$UPSTREAM_COMMIT" GITHUB_REF_NAME="$UPSTREAM_TAG" GITHUB_HEAD_REF= pnpm run build)
# No --x64: an explicit arch flag stages native deps into a directory the
# upstream source path rejects; the default arch (x64 on the runner) reuses
# the deps that `pnpm run build` staged.
(cd "$app" && pnpm run builder --win --dir --publish never \
  "-c.extraMetadata.version=${UPSTREAM_TAG#v}")

unpacked="$app/release/win-unpacked"
if [ ! -d "$unpacked" ]; then
  echo "error: expected electron-builder output at $unpacked" >&2
  exit 1
fi

echo "==> Packaging $artifact"
mkdir -p "$out"
rm -f "$out/$artifact"
# Windows' own bsdtar (not Git Bash's GNU tar) writes a standard ZIP, with
# forward-slash paths, from the -a suffix.
wintar="$(cygpath -u "$SYSTEMROOT")/System32/tar.exe"
(cd "$unpacked" && "$wintar" -a -c -f "$(cygpath -w "$out/$artifact")" -- *)

echo "Built dist/$artifact"
