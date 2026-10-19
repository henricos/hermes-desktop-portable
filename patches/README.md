# Patches

Patches applied on top of the pinned upstream (`../upstream.lock`) by `scripts/apply-patches.sh`, in file-name order, as commits (`git am -3`).

Conventions:

- **Produced by `scripts/refresh-patches.sh`**, never written by hand. It exports `git format-patch` files named `NNNN-subject.patch`, numbered in apply order. To change a patch, edit the commit inside `./upstream` and refresh. See `../docs/updating-upstream.md`.
- **One concern per patch**, kept small. A patch that stops applying after an upstream bump should be easy to rebase.
- **The commit message is the documentation.** Subject: what the patch does. Body: why it is needed, and which upstream issue it relates to.

Current:

| Patch | Guarantees |
|---|---|
| `0001-Rename-the-light-variant-and-mark-it-unofficial` | Display name "Hermes Portable", executable `HermesPortable.exe`, and the About screen carries the unofficial-distribution notice |
| `0002-Keep-all-data-next-to-the-executable-on-Windows` | All data (settings, tokens, logs) lives in `data\` next to the executable, tokens are encrypted with DPAPI by default, and no `hermes://` protocol handler is registered; deleting the folder uninstalls everything |
| `0003-Point-the-update-notice-to-this-project-s-releases` | The About screen's update card points to this project's Releases instead of "managed by the package owner" |

Every change inside a patch is marked with a `hermes-desktop-portable:` comment, so it is easy to find in the upstream tree.

Possible later improvement, only if it stays small and easy to maintain (see "Why this exists" in the README): remote-only enforcement. A single policy predicate checked at the main-process chokepoints (`ensureRuntime`, backend resolution, local backend spawn, local-mode IPC handlers, connection-config parsing), plus removal of the local options in the renderer.
