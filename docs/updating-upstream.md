# Updating upstream

Move the package to a newer Hermes release, or change the patches. Works on any OS with Git and Bash (Git Bash on Windows). Then build [locally](build-local.md) or [on GitHub Actions](build-github-actions.md).

Every command below that creates a commit needs a Git identity, and the project's patches carry a build identity rather than a person's. Define this once per shell and use `$G` where shown:

```bash
G='git -c user.name=hermes-desktop-portable -c user.email=build@hermes-desktop-portable.invalid'
```

After `npm ci` has run in `./upstream`, upstream's lefthook pre-commit hook runs eslint on each commit; prefix a command with `LEFTHOOK=0` to skip it.

## Bump to a new Hermes release

A bump is a review of [intents](intents.md), not only a re-apply: a patch that still applies may no longer be needed, may use a mechanism upstream replaced, or may miss a new path that breaks its intent.

### 1. Review the new upstream before applying

Fetch both pins without touching `upstream.lock`:

```bash
cd upstream
git fetch -q --depth=500 origin tag <old tag> tag <new tag>
git diff --stat <old tag> <new tag> -- $(grep -h '^diff --git' ../patches/*.patch | awk '{print substr($3,3)}' | sort -u)
git diff <old tag> <new tag> -- apps/desktop/electron/main.ts | less     # and the other files listed
```

Then, for each intent in [`intents.md`](intents.md):

1. Run its **Revisit on bump** checks against the new tag (`git grep <pattern> <new tag> -- apps/desktop`).
2. Check its **Obsolete when** condition: did upstream start doing it itself?
3. Decide: keep, change the mechanism (a new upstream switch, code that moved), drop, or extend (a new path that breaks the promise).

Also list the switches upstream honors and compare them with the old tag. A new one can replace a code change ("upstream switches first" in [`patches/README.md`](../patches/README.md)):

```bash
diff <(git grep -ohE 'HERMES_DESKTOP_[A-Z_]+' <old tag> -- apps/desktop/electron | sort -u) \
     <(git grep -ohE 'HERMES_DESKTOP_[A-Z_]+' <new tag> -- apps/desktop/electron | sort -u)
```

Write down the decisions; they go into the bump commit's message.

### 2. Apply

```bash
scripts/bump-upstream.sh v0.23.0
```

This repoints `upstream.lock` (stable `vX.Y.Z` release tags only), fetches the new commit into `./upstream`, applies `patches/` and re-exports them against the new base. If a patch fails, see [If a patch fails](#if-a-patch-fails). Carry out the decisions from step 1 as patch changes (see [Change or add a patch](#change-or-add-a-patch)).

### 3. Verify every intent

- Each intent's marker still sits at each place its **How** names: `git grep -n 'hermes-desktop-portable(<id>)' -- apps/desktop` in `./upstream`.
- Typecheck, lint and test (`npm run typecheck`, `npm run lint`, and the tests of the files the patches touch, in `upstream/apps/desktop` after `npm ci` at `upstream/`).
- Update [`intents.md`](intents.md), [`patches/README.md`](../patches/README.md), [`usage.md`](usage.md) and the [test checklist](build-github-actions.md#testing-a-package) when a mechanism or a promise changed.

Review `git diff patches/` and commit `upstream.lock`, `patches/` and the docs together. Build, and run [Testing a package](build-github-actions.md#testing-a-package): each check there names the intent it proves. The release revision restarts at `-r1` (see [Releases](build-github-actions.md#releases)).

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

## If a patch no longer fits

Sometimes upstream has rewritten the code a patch touches, and resolving the conflict line by line would not keep the patch's intent. Rewrite that part of the patch against the new code instead. Work in the `git am` session that stopped:

```bash
cd upstream
git am --show-current-patch=raw     # the patch's message, and its diff against the old base
git checkout HEAD -- <file>         # drop the half-applied file; start from the new upstream code
```

1. Read the intent: the patch's commit message (one bullet per change), the `hermes-desktop-portable:` comments in the old diff, and the patch's row in [`patches/README.md`](../patches/README.md). Those rows are the guarantees the rewrite must keep.
2. Find where upstream moved the code. Search the new tree for the identifiers and strings the old diff touched, and see what upstream changed between the two pins: `git log --oneline <old pin>..<new pin> -- <file>` and `git log -S'<identifier>' <old pin>..<new pin>`.
3. Make the smallest change that restores each guarantee, keeping the `hermes-desktop-portable:` comments, then `git add` and `$G am --continue`.
4. If upstream now does what the patch did, drop that part, or the whole patch (`$G am --skip`) and its row in `patches/README.md`.
5. Update the commit message if the change is no longer the same (see [Change or add a patch](#change-or-add-a-patch)), then refresh.

Verify before committing: typecheck and lint the desktop app (`npm run typecheck` and `npm run lint` in `upstream/apps/desktop`, after `npm ci` at `upstream/`), then build on GitHub Actions and run [Testing a package](build-github-actions.md#testing-a-package).

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

`refresh-patches.sh` refuses to run while an `am` or a rebase is unfinished. Never edit a `.patch` file by hand.

Always start from `fetch-upstream.sh && apply-patches.sh`, so that you change the pinned source with every patch already applied, never a newer upstream or a stale checkout. Before adding a patch, check which patch already touches each file you change (`grep '^diff --git' patches/*.patch`): no upstream file belongs to two patches, so a change to such a file is a `--fixup` of that patch, and the patch's message and its row in [`patches/README.md`](../patches/README.md) must cover the new change. Keep changes to one-line conditions next to upstream code where you can; reindenting a block makes every later rebase harder.

## Scripts

| Script | Does |
|---|---|
| `fetch-upstream.sh` | Pinned commit into `./upstream`, discarding local changes and any unfinished `am` or rebase (keeps `node_modules`) |
| `apply-patches.sh` | `patches/*.patch` as commits, with `git am -3` |
| `refresh-patches.sh` | Commits in `./upstream` back to `patches/` |
| `bump-upstream.sh <tag>` | New pin, then fetch, apply and refresh |
| `build.sh [--version v]` | Fetch, apply, `npm ci`, build, zip into `dist/` (Windows only) |
