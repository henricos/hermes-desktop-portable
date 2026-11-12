# Using the package

## Where your data lives

Everything the app keeps (settings, gateway tokens, logs) lives in a `data` folder next to `HermesPortable.exe`. The app is built to leave `%APPDATA%`, `%LOCALAPPDATA%` and the registry alone, so deleting the unpacked folder uninstalls it; this is checked before each release (see [Testing a package](build-github-actions.md#testing-a-package)).

One exception you may notice: while the app runs, an empty `%APPDATA%\Hermes` folder exists. Electron creates it at startup, before the app can redirect it; nothing is written there, and the app removes it when it quits. If the app is killed instead (Task Manager, a crash), the empty folder stays behind; delete it by hand.

Windows itself remembers every program you run (for example in the `MuiCache` and Compatibility Assistant registry keys, or per-app audio settings). Those entries hold the executable's path, not your settings or tokens, and are not the app's to remove.

As in upstream Hermes Desktop, gateway tokens and sign-ins are stored in `data` without encryption, so a copy of the folder carries them too. Keep that in mind before copying or sharing it.

## Upgrading

Unpack each new version to a new folder and connect to your gateways again. Carrying a `data` folder over from an earlier version is not supported: upstream changes how it stores data between releases (v0.23.0, for example, moved saved gateways to a new store), and this project does not test those migrations. Moving `data` into the new folder may work, but if anything misbehaves, start again from a fresh folder.

## Gateways

Your Hermes must expose its gateway to this machine, for example over your LAN, a VPN or Tailscale; see the upstream [documentation](https://hermes-agent.nousresearch.com/docs/) for gateway setup. You can add or change gateways later under **Settings → Gateways**.

Run the same Hermes version on the server as the package was built from: `v0.23.1-r1` needs Hermes `v0.23.1` (the **Built from** badge in the README shows the current one). Upgrade the server whenever you upgrade the package. The desktop and the gateway speak a protocol that changes between releases, and a mismatch fails on ordinary use, for example every prompt failing with `invalid params for prompt.submit: ... Extra inputs are not permitted` and a hint to run `hermes update`.

## No local install

The package cannot install Hermes on your machine. The setup screen only offers **Connect to existing Hermes**, and "This device" is not shown in the gateway list. A few upstream options that rely on a local Hermes are still visible: the **Local gateway** connection mode, the **This device** entry under **Settings → Gateways → Saved connections**, and **Repair** on a connection-error screen. Choosing one shows an error instead of downloading upstream's installer; switch back to your remote gateway.
