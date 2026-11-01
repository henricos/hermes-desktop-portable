# Patches

Patches applied on top of the pinned upstream (`../upstream.lock`) by `scripts/apply-patches.sh`, in file-name order, as commits (`git am -3`).

Conventions:

- **Produced by `scripts/refresh-patches.sh`**, never written by hand. It exports `git format-patch` files named `NNNN-subject.patch`, numbered in apply order. To change a patch, edit the commit inside `./upstream` and refresh. See `../docs/updating-upstream.md`.
- **No upstream file in two patches.** Patches are grouped by the files they change, not by feature: a new change to a file that a patch already touches goes into that patch. A conflict after an upstream bump then stays inside one patch, and no patch depends on another one's context. A patch may still change several files, and may carry several concerns.
- **Kept small.** Prefer a one-line condition next to upstream code over moving or reindenting it: a patch that stops applying after a bump should be easy to rebase or rewrite.
- **The commit message is the documentation.** Subject: what the patch does. Body: why it is needed, which upstream issue it relates to, and one bullet per change, so the patch can be rewritten from its message when upstream has moved the code (see [`../docs/updating-upstream.md`](../docs/updating-upstream.md#if-a-patch-no-longer-fits)).

Current:

| Patch | Guarantees |
|---|---|
| `0001-Rename-the-light-variant-and-mark-it-unofficial` | Display name "Hermes Portable", executable `HermesPortable.exe`, and the About screen carries the unofficial-distribution notice |
| `0002-Keep-data-portable-and-refuse-local-runtimes` | All data (settings, tokens, logs) lives in `data\` next to the executable, tokens are encrypted with DPAPI by default, and no `hermes://` protocol handler is registered; deleting the folder uninstalls everything. The first-launch bootstrap never runs, without breaking the remote gateway, and "This device" is never enumerated |
| `0003-Point-the-update-notice-to-this-project-s-releases` | The About screen's update card points to this project's Releases instead of "managed by the package owner" |
| `0004-Hide-the-local-install-option-on-the-setup-screen` | The first-run screen offers only **Connect to existing Hermes** |

Every change inside a patch is marked with a `hermes-desktop-portable:` comment, so it is easy to find in the upstream tree.

Possible later improvements, only if they stay small: hide the remaining local options (the **Local gateway** mode, "This device" in Saved connections, **Repair**). They already fail safely through the `0002` refusal. Filtering "This device" out of the connection list is not enough on its own: the Add connection form would then offer a Local kind.
