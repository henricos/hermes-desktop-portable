# Hermes Desktop Portable

<p align="center"><i>An unofficial portable repack of Hermes Desktop for Windows, for use with a remote Hermes.</i></p>

<p align="center">
  <a href="https://github.com/henricos/hermes-desktop-portable/releases">Releases</a> | <a href="#building-your-own-package">Building</a> | <a href="https://github.com/NousResearch/hermes-agent">Upstream: Hermes Agent</a>
</p>
<p align="center">
  <a href="https://github.com/henricos/hermes-desktop-portable/actions/workflows/build-windows.yml"><img src="https://img.shields.io/github/actions/workflow/status/henricos/hermes-desktop-portable/build-windows.yml?branch=main&style=for-the-badge&label=Build" alt="Build status"></a>
  <a href="https://github.com/henricos/hermes-desktop-portable/releases"><img src="https://img.shields.io/github/v/release/henricos/hermes-desktop-portable?style=for-the-badge&label=Release" alt="Latest release"></a>
  <a href="upstream.lock"><img src="https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fhenricos%2Fhermes-desktop-portable%2Fmain%2Fupstream.lock&query=%24.UPSTREAM_TAG&label=Built%20from&color=blueviolet&style=for-the-badge" alt="Pinned upstream version"></a>
  <a href="https://github.com/NousResearch/hermes-agent/releases/latest"><img src="https://img.shields.io/github/v/release/NousResearch/hermes-agent?style=for-the-badge&label=Upstream%20latest&color=lightgrey" alt="Latest upstream release"></a>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20x64-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Platform: Windows x64">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Status-Unofficial-orange?style=for-the-badge" alt="Unofficial distribution">
</p>

**An unofficial portable repack of [Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop) for Windows, for use with a Hermes that runs on another machine.** Unpack a folder and run `HermesPortable.exe`: it connects to the Hermes Agent you already run somewhere else (a home server, NAS, VPS or VM), with no installer and no local agent. No Python, no uv, no Git, no Node on your workstation: just the desktop app and the gateway it talks to.

The app is upstream's own code, repackaged. A few small, readable [patches](patches/README.md) adapt it to the portable layout; they do not change how the app works.

> [!IMPORTANT]
> This is an **unofficial, independent repack**. It is not affiliated with or endorsed by Nous Research. Report problems with this package here, not upstream.

## Who this is for

| You have | Use |
|---|---|
| Hermes Agent on another machine, and want only the desktop app here | **This project** |
| No Hermes yet, and want agent and desktop on this machine | The [official installer](https://hermes-agent.nousresearch.com/desktop) |
| Hermes Agent already installed on this machine | The [official installer](https://hermes-agent.nousresearch.com/desktop), which brings the desktop and builds on the existing install |

> [!CAUTION]
> **Do not use this package on a machine that already has Hermes Agent installed.** "Portable" is about how it ships, not what it contains: the agent is not inside, and the package expects it to live elsewhere. With a local Hermes present, the app may silently use it instead of asking for a gateway, and a `HERMES_HOME` environment variable left by that install makes the app use that folder instead of its own `data` folder.

<table>
<tr><td><b>Client only, by design</b></td><td>The desktop UI runs locally; tools, files, sessions, memory and automations stay on your remote Hermes.</td></tr>
<tr><td><b>Nothing global on the client</b></td><td>Electron carries its own embedded runtime, like VS Code. Nothing is added to <code>PATH</code>, and nothing collides with any Python, Node or Git you already have.</td></tr>
<tr><td><b>Portable</b></td><td>Ships as a ZIP: unpack and run. Settings, tokens and logs stay in a <code>data</code> folder next to the executable; remove the folder to uninstall.</td></tr>
<tr><td><b>Upstream source, small diff</b></td><td>Repacked from a pinned upstream release plus a handful of reviewable patches. Not a fork.</td></tr>
<tr><td><b>Auditable CI builds</b></td><td>Every published package is built on GitHub Actions from this repository, from a pinned upstream commit and the patches you can read here. You never build anything to use it.</td></tr>
</table>

---

## Why this exists

The official Windows download is a bootstrap installer: before the desktop app exists, it stages a full local Hermes Agent (Python, uv, Git and a checkout of the repository). For a machine that should only talk to a remote gateway, that is gigabytes of unused runtime and tooling.

Two upstream issues describe the gap, and this project treats them differently:

- **A desktop-only install** ([#38519](https://github.com/NousResearch/hermes-agent/issues/38519)): install just the desktop app and connect it to a Hermes that already runs elsewhere. This is what this project solves, by repacking upstream's desktop app as a portable ZIP. Upstream has said a dedicated remote-only package is [not planned for now](https://github.com/NousResearch/hermes-agent/issues/134308).
- **Protection against local activation** ([#135920](https://github.com/NousResearch/hermes-agent/issues/135920)): the desktop app has actions (a setup choice, repair and fallback buttons, local gateway options) that start a full local install. A repack like this one would ideally block them all. That is a possible later improvement, not a goal: the priority here is to repackage upstream, not to change its behavior. Once the repack itself has proven to work, blocking those actions will be evaluated, and adopted only if it fits in a few patches that stay easy to maintain. Until then, the [warning in Quick Install](#quick-install) tells you which actions to avoid.

## Quick Install

1. Download `HermesPortable-<version>-win-x64.zip` from the [latest release](https://github.com/henricos/hermes-desktop-portable/releases/latest).
2. Unpack it to a folder of your own, for example `%USERPROFILE%\Apps\HermesPortable`: writable (not under `Program Files`) and not synced by OneDrive.
3. Run `HermesPortable.exe`. The package is not code-signed, so SmartScreen may warn on first launch.
4. On the setup screen, choose **Connect to existing Hermes** and enter your gateway's URL and credentials. Your Hermes must be reachable from this machine (LAN, VPN, Tailscale).

> [!WARNING]
> Never choose **Install Hermes locally**, **Repair**, **Use local gateway**, or a **Local** / **This device** gateway: each one installs a full local Hermes. See [Why this exists](#why-this-exists).

Settings, tokens and logs stay in a `data` folder next to the executable: delete the folder to uninstall, and keep `data` when you upgrade. Details in [Using the package](docs/usage.md).

## How it is built

The repository holds only the difference from upstream:

```
upstream.lock          pinned upstream tag and commit
patches/               small patches applied on top of it
scripts/               fetch upstream, apply and refresh patches, build
docs/                  how to use the package, build it and update upstream
.github/workflows/     Windows build and release on GitHub Actions
```

On every build, a `windows-latest` runner checks out the pinned upstream commit, applies `patches/` in order, builds `apps/desktop` with upstream's remote-only `light` variant and packages the unpacked app as a ZIP.

Package versions follow upstream: `v0.22.2-r1` is the first revision of this project built from Hermes `v0.22.2`. The **Built from** badge above reads the pinned tag straight from [`upstream.lock`](upstream.lock).

### Design choices

- **Patches over a pinned upstream, not a fork.** Upstream moves fast; keeping only the difference makes every bump a rebase of a few small patches instead of a merge of a whole monorepo.
- **Portable ZIP first.** Upstream's Windows target is MSIX, which needs a trusted signing certificate to install without developer mode. A ZIP runs anywhere; a signed MSIX may follow.
- **No gateway baked in.** Builds are public and generic; every user enters their own gateway on first run.

## Building your own package

> [!TIP]
> **You probably don't need to.** Ready-made packages are on the [Releases](https://github.com/henricos/hermes-desktop-portable/releases) page.

- [Build on GitHub Actions in your fork](docs/build-github-actions.md): nothing to install on your machine.
- [Build locally on Windows](docs/build-local.md): needs Git for Windows and Node.
- [Update to a newer Hermes release, or change the patches](docs/updating-upstream.md).

With an AI coding agent, clone the repository and ask it, for example, to "build a package for Hermes v0.23.0"; [`AGENTS.md`](AGENTS.md) points it to these documents.

## Contributing

Issues and pull requests are welcome. Keep patches small and focused on one concern; see [`patches/README.md`](patches/README.md). Changes that make sense for every Hermes user belong upstream in [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent).

## License

MIT for this repository's own files; see [`LICENSE`](LICENSE). Hermes Desktop is MIT-licensed by Nous Research; see [`NOTICE`](NOTICE).
