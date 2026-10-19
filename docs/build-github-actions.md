# Building on GitHub Actions

The workflow `.github/workflows/build-windows.yml` builds the ZIP on a clean `windows-latest` runner by running `scripts/build.sh`. It is written to run in a fork as well, so you can build a package without installing anything on your machine.

## In your fork

1. Fork the repository. In the fork's **Actions** tab, click **I understand my workflows, go ahead and enable them**.
2. Run the workflow, from the Actions tab (**build-windows** → **Run workflow**) or with `gh`, naming your fork explicitly (a clone of a fork defaults to the original repository):

   ```bash
   gh workflow run build-windows.yml -R <you>/hermes-desktop-portable
   gh run list -w build-windows.yml -R <you>/hermes-desktop-portable -L 1   # get the run ID
   gh run watch <run-id> -R <you>/hermes-desktop-portable
   gh run download <run-id> -R <you>/hermes-desktop-portable -D dist
   ```

3. The artifact is named `HermesPortable-<version>-win-x64` and holds the ZIP and a `SHA256SUMS.txt`. Downloaded from the web page it arrives as a ZIP containing that ZIP; unpack the outer one first.

Pushes to `main` and pull requests also build it. Artifacts are kept for 30 days and versioned `<upstream tag>-dev.<commit>`, for example `v0.22.2-dev.1a2b3c4`, where the commit is this repository's (for a pull request, GitHub's merge commit). That version only names the artifact; it is not a tag. Pull requests from forks run with a read-only token, and a first-time contributor's run waits for approval.

If you publish releases from your fork, also change:

- the README's badges and links, which point to `henricos/hermes-desktop-portable`;
- the URL in patch `0003`, which the app shows in its update notice. Change it through [Updating upstream](updating-upstream.md#change-or-add-a-patch), never by editing the `.patch` file.

## Releases

Maintainer only. An AI agent proposes the tag and waits for approval (see `AGENTS.md`).

Versions are `v<upstream tag>-r<revision>`: `v0.22.2` is `UPSTREAM_TAG` in `upstream.lock`, and `-r1`, `-r2`, ... count this project's own revisions on that upstream, restarting at `-r1` after every bump.

1. Tag a commit that is already on `main` and whose build is green, and push the tag:

   ```bash
   git tag v0.22.2-r1 && git push origin v0.22.2-r1
   ```

   The workflow builds the ZIP and creates a **draft** release with the ZIP, a `SHA256SUMS.txt` and notes naming the upstream tag and commit. If the tag does not match `upstream.lock`, the build fails and no release is created; delete the tag (`git push origin :refs/tags/<tag>` and `git tag -d <tag>`) and tag again.
2. Download the ZIP from the draft and test it (below).
3. Publish: `gh release edit v0.22.2-r1 --draft=false`.

## Testing a package

On a Windows machine with no Hermes Agent installed and no `HERMES_HOME` variable:

1. Before the first launch, note what is in `%APPDATA%` and `%LOCALAPPDATA%`.
2. Unpack the ZIP, run `HermesPortable.exe`, connect to a gateway, use the app, and quit it.
3. Check:
   - The About screen shows the unofficial-build notice, and its update card points to this project's releases.
   - Everything the app wrote is under `data\` in the unpacked folder, including `secure-token-storage.json` with `"on":true` (DPAPI-encrypted tokens).
   - Nothing new in `%APPDATA%\Hermes*` or `%LOCALAPPDATA%\hermes*` compared with step 1.
   - No `HKCU\Software\Classes\hermes` registry key.
   - No local runtime: no `hermes-agent` checkout, venv, Python, uv or Git.
