# Updating upstream

Move the package to a newer Hermes release, or change the patches. Works on any OS with Git and Bash (Git Bash on Windows). Then build [locally](build-local.md) or [on GitHub Actions](build-github-actions.md).

Every command below that creates a commit needs a Git identity, and the project's patches carry a build identity rather than a person's. Define this once per shell and use `$G` where shown:

```bash
G='git -c user.name=hermes-desktop-portable -c user.email=build@hermes-desktop-portable.invalid'
```

After `npm ci` has run in `./upstream`, upstream's lefthook pre-commit hook runs eslint on each commit; prefix a command with `LEFTHOOK=0` to skip it.

## Bump to a new Hermes release

```bash
scripts/bump-upstream.sh v0.23.0
```

This repoints `upstream.lock` (stable `vX.Y.Z` release tags only), fetches the new commit into `./upstream`, applies `patches/` and re-exports them against the new base. If it succeeds, review `git diff patches/` and commit `upstream.lock` and `patches/` together. The release revision restarts at `-r1` (see [Releases](build-github-actions.md#releases)).

## If a patch fails

`git am` stops on the failing patch and leaves the conflicts in `./upstream`: conflict markers in the files, or, when upstream deleted a file the patch changes, a modify/delete conflict that `git status` lists.

```bash
cd upstream
git status                  # conflicted files
# fix them, keeping the intent of the patch
git add <files>             # or git rm <file>
$G am --continue            # repeat for each failing patch
cd ..
scripts/refresh-patches.sh  # write the rebased patches back to patches/
```

Review `git diff patches/` before committing: a rebased patch should do what it did before, against new context.

## Change or add a patch

```bash
scripts/fetch-upstream.sh && scripts/apply-patches.sh   # one commit per patch in ./upstream
cd upstream
source ../upstream.lock
git log --oneline "$UPSTREAM_COMMIT"..                  # the patch commits
# edit files, then stage them:
git add <files>
```

Then either amend an existing patch:

```bash
$G commit --fixup=<commit from the log above>
GIT_SEQUENCE_EDITOR=: $G rebase -i --autosquash "$UPSTREAM_COMMIT"
```

or add a new one:

```bash
$G commit -m "Short subject" -m "Why the change is needed."
```

If the rebase stops on a conflict, fix it, `git add`, and `$G rebase --continue`. Finally, from the repository root:

```bash
cd .. && scripts/refresh-patches.sh
```

`refresh-patches.sh` refuses to run while an `am` or a rebase is unfinished. Never edit a `.patch` file by hand. One concern per patch; the commit message is its documentation (see [`patches/README.md`](../patches/README.md)).

## Scripts

| Script | Does |
|---|---|
| `fetch-upstream.sh` | Pinned commit into `./upstream`, discarding local changes and any unfinished `am` or rebase (keeps `node_modules`) |
| `apply-patches.sh` | `patches/*.patch` as commits, with `git am -3` |
| `refresh-patches.sh` | Commits in `./upstream` back to `patches/` |
| `bump-upstream.sh <tag>` | New pin, then fetch, apply and refresh |
| `build.sh [--version v]` | Fetch, apply, `npm ci`, build, zip into `dist/` (Windows only) |
