# Intents

What this package changes in upstream's behavior, and why. Patches are only the current way to get there: they are grouped by file (see [`patches/README.md`](../patches/README.md)), so one patch can serve several intents and one intent can span several patches. On every bump, start here, not from the patches: an intent may need a different mechanism on the new upstream, may no longer be needed, or may have new gaps that the old patches do not cover.

Each change in the upstream tree carries a marker comment with its intent's id, `hermes-desktop-portable(<id>):`, so `git -C upstream grep -n 'hermes-desktop-portable(<id>)'` lists where an intent is implemented. Each patch's commit message ends with an `Intents:` line.

Every intent below lists:

- **Promise**: what users can rely on. It is checked in [Testing a package](build-github-actions.md#testing-a-package) and told to users in [`usage.md`](usage.md).
- **How**: the mechanisms in use today. Prefer an upstream switch (an environment variable set in `electron/entry.ts`) over a code change.
- **Revisit on bump**: what to look for in the new upstream before applying the patches.
- **Obsolete when**: the upstream change that would make the intent's code unnecessary.

## `portable-data`: nothing outside the unpacked folder

**Promise.** Settings, gateway tokens and logs live in `data\` next to `HermesPortable.exe`. The app creates nothing in `%APPDATA%` or `%LOCALAPPDATA%` and registers nothing in the registry, so deleting the folder uninstalls it. Entries that Windows itself writes for any executable (`MuiCache`, Compatibility Assistant, per-app audio settings) are out of scope.

**How.**

- `entry.ts` sets `HERMES_DESKTOP_USER_DATA_DIR` to `data\`, which upstream also uses for the Hermes home (`data\hermes-home`).
- `entry.ts` pins `HERMES_HOME` to `data\hermes-home`: an inherited `HERMES_HOME` takes precedence over `HERMES_DESKTOP_USER_DATA_DIR` in `resolveDesktopHermesHome` (`electron/data-paths.mjs`).
- `entry.ts` sets `HERMES_DESKTOP_SKIP_PROTOCOL_REGISTRATION=1`: no `HKCU\Software\Classes\hermes`.
- `entry.ts` also applies `userData` itself before main is imported, because modules main imports read it as they load (for example the link-preview favicon cache in `link-metadata.ts`), and on quit removes Electron's default folder (`%APPDATA%\Hermes`, from the package's `productName`) while it is empty.

**Revisit on bump.** Anything new that writes to a fixed location before or regardless of `userData`: module-level `app.getPath(` calls in files main imports, `app.getPath(` calls for `appData`, `temp` or `home`, `mkdirSync` near startup, registry writes (`setAsDefaultProtocolClient`, `reg add`, `setLoginItemSettings`, jump lists, notification registration). Check how the Hermes home is resolved in `data-paths.mjs`.

**Obsolete when.** Upstream ships a portable mode that does all of the above.

## `encrypted-tokens`: tokens are encrypted by default

**Promise.** Gateway tokens in `data\` are encrypted with Windows DPAPI, so a copied folder does not carry usable credentials to another Windows account.

**How.** `main.ts`, `secretStoragePolicy()`: on Windows, when no choice has been saved, start with encryption on.

**Revisit on bump.** Changes to the secret-storage policy (`electron/secret-storage-policy.ts`) and to its default.

**Obsolete when.** Upstream encrypts by default on Windows.

## `remote-only`: never install, run or offer a local Hermes

**Promise.** The app only connects to Hermes gateways running elsewhere. It never downloads upstream's installer, never sets up Python, uv or Git, and never uses a Hermes already installed on the machine. The setup screen offers only **Connect to existing Hermes**. A few upstream options that need a local Hermes stay visible (see [No local install](usage.md#no-local-install)), but choosing one shows an error instead of installing.

**How.**

- `entry.ts` sets `HERMES_DESKTOP_IGNORE_EXISTING=1`: backend resolution skips installed runtimes.
- `main.ts`, `ensureRuntime()`: the light variant refuses the first-launch bootstrap. This is the single entry point to `runBootstrap`. The refusal does not set `bootstrapFailure`: that latch is global, and setting it would make the remote primary fail too until the app restarts.
- `main.ts`, the gateway roster: "This device" is left out, so nothing dials a local backend in the background and the profile rail shows neither an unreachable local entry nor a switch to it.
- `main.ts` sends `light` with the setup-choice event and snapshot. `desktop-install-overlay.tsx` hides the local option, and `global.d.ts` types the flag.

**Known gaps.** The **Local gateway** connection mode, "This device" under Saved connections and **Repair** are still shown; they fail safely through the bootstrap refusal. Hiding them is a possible later change, only if it stays small. Filtering "This device" out of the connection list is not enough on its own: the Add connection form would then offer a Local kind.

**Revisit on bump.** Every caller of `runBootstrap` and `ensureRuntime`, and any new path that spawns a local backend or downloads `install.ps1` / `install.sh`. Whether the `light` variant still means "no runtime" (`isLightVariant()`, the install stamp's `payload`). Whether the failure latch (`latchedBootFailure()`) still exists. New local options in the renderer (setup, connection errors, Settings → Gateways).

**Obsolete when.** Upstream's light variant blocks local runtimes itself ([#135920](https://github.com/NousResearch/hermes-agent/issues/135920)). A pull request upstream for the bootstrap refusal is the way to get there.

## `identity`: clearly an unofficial build

**Promise.** The app is named "Hermes Portable", the executable is `HermesPortable.exe` (no spaces), and the About screen is headed "Hermes Portable", says it is an unofficial build not affiliated with Nous Research, and links to the upstream commit it was built from. Other upstream strings that say "Hermes Desktop" are kept: the package is a repack of Hermes Desktop.

**How.** `product-identity.cjs` names the light variant and its executable; `product-identity.test.ts` follows the name; `src/i18n/en.ts` heads About with the name (English only; other languages keep "Hermes"); `update-status.tsx` shows the notice. About links its commit to the pinned upstream commit, because `scripts/build.sh` records that commit in the build stamp instead of the patched one.

**Revisit on bump.** How the product identity is derived (`product-identity.cjs`), and where About renders the version block.

**Obsolete when.** Never; this is the project's own identity.

## `update-source`: updates come from this project

**Promise.** The About screen's update card tells users to download new versions from this project's Releases.

**How.** `updater/external.ts` replaces the "managed by the package owner" message.

**Revisit on bump.** Whether the light variant on Windows still lacks a self-updater, and where the external-update message lives.

**Obsolete when.** Never, while this project publishes the package.
