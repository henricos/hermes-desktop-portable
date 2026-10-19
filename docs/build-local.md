# Building locally on Windows

Build the portable ZIP on your own Windows machine. If you would rather not set up Node on Windows, [build on GitHub Actions in a fork](build-github-actions.md) instead.

The package is built on Windows only: a cross-build from Linux or WSL is not supported (native modules, and editing the Windows executable).

## Prerequisites

- Windows 10 1803 or later (the ZIP is made with Windows' own `tar.exe`).
- [Git for Windows](https://git-scm.com/download/win), for Git Bash.

## 1. Configure Git and clone

The upstream tree has long paths, and its files must keep LF line endings:

```bash
git config --global core.longpaths true
git config --global core.autocrlf false
git clone https://github.com/henricos/hermes-desktop-portable.git /c/src/hermes-desktop-portable
cd /c/src/hermes-desktop-portable
```

Clone to a short path such as `C:\src`.

## 2. Get the pinned Node and npm

Upstream pins exact versions, and its `.npmrc` sets `engine-strict`, so another npm can make `npm ci` fail. `build.sh` only warns when the Node major version differs, and does not check npm at all.

```bash
scripts/fetch-upstream.sh    # pinned upstream into ./upstream
```

Open `upstream/pm/lock.json` and read `packages.node.version` and `packages.npm.version` (for v0.22.2: Node 26.7.0, npm 12.0.2). Then, for this Git Bash session:

1. Download the Node `win-x64` ZIP of that version from [nodejs.org](https://nodejs.org/dist/) and unpack it, for example to `C:\tools\node-v26.7.0-win-x64`.
2. Put it on `PATH` and install the pinned npm into it:

```bash
export PATH="/c/tools/node-v26.7.0-win-x64:$PATH"
npm install --global npm@12.0.2
node --version && npm --version
```

Nothing is installed system-wide; closing the shell undoes the `PATH` change.

## 3. Build

```bash
scripts/build.sh
```

`build.sh` fetches upstream again (reusing `./upstream`), applies the patches, runs `npm ci`, builds and zips. `--version` is optional and only names the ZIP; it defaults to `<UPSTREAM_TAG>-dev`. Keep `-r<N>` for published releases.

Output:

- `dist/HermesPortable-v0.22.2-dev-win-x64.zip`, the package;
- `upstream/apps/desktop/release/win-unpacked/`, the same app unpacked, ready to run.

`./upstream` and `./dist` are ignored by git. To build a newer Hermes version, update the pin first: see [Updating upstream](updating-upstream.md).
