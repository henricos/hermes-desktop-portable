# Patches

Patches applied on top of the pinned upstream (`../upstream.lock`) by `scripts/apply-patches.sh`, in file-name order, as commits (`git am -3`).

Conventions:

- **Produced by `scripts/refresh-patches.sh`**, never written by hand. It exports `git format-patch` files named `NNNN-subject.patch`, numbered in apply order. To change a patch, edit the commit inside `./upstream` and refresh. See `../docs/updating-upstream.md`.
- **No upstream file in two patches.** Patches are grouped by the files they change, not by feature: a new change to a file that a patch already touches goes into that patch. A conflict after an upstream bump then stays inside one patch, and no patch depends on another one's context. A patch may still change several files, and may carry several concerns.
- **Upstream switches first.** When upstream already honors an environment variable for a behavior (`HERMES_DESKTOP_USER_DATA_DIR`, `HERMES_DESKTOP_SKIP_PROTOCOL_REGISTRATION`, `HERMES_DESKTOP_IGNORE_EXISTING`, ...), set it in `electron/entry.ts` before main is imported instead of changing the code it controls. Those switches are upstream's own interface, covered by its tests, and survive refactors that move the code. Look for new ones on every bump: `git grep -ohE 'HERMES_DESKTOP_[A-Z_]+' -- apps/desktop/electron | sort -u`.
- **Kept small.** Prefer a one-line condition next to upstream code over moving or reindenting it: a patch that stops applying after a bump should be easy to rebase or rewrite.
- **The commit message is the documentation.** Subject: what the patch does. Body: why it is needed, which upstream issue it relates to, one bullet per change, and a final `Intents:` line, so the patch can be rewritten from its message when upstream has moved the code (see [`../docs/updating-upstream.md`](../docs/updating-upstream.md#if-a-patch-no-longer-fits)).

Current:

| Patch | Files (`apps/desktop/`) | Intents |
|---|---|---|
| `0001-Rename-the-light-variant-and-mark-it-unofficial` | `product-identity.cjs`, `electron/product-identity.test.ts`, `src/components/update-status.tsx`, `src/i18n/en.ts` | `identity` |
| `0002-Keep-data-portable-and-refuse-local-runtimes` | `electron/entry.ts`, `electron/main.ts` | `portable-data`, `encrypted-tokens`, `remote-only` |
| `0003-Point-the-update-notice-to-this-project-s-releases` | `electron/updater/external.ts` | `update-source` |
| `0004-Hide-the-local-install-option-on-the-setup-screen` | `src/components/desktop-install-overlay.tsx`, `src/global.d.ts` | `remote-only` |

What each intent promises, how it is implemented and what to re-check on a bump: [`../docs/intents.md`](../docs/intents.md).

Every change inside a patch is marked with a `hermes-desktop-portable(<intent>):` comment, so `git grep 'hermes-desktop-portable(remote-only)'` in `./upstream` lists everything one intent changes. A new change gets the marker of the intent it serves, and a patch's commit message ends with an `Intents:` line listing them.
