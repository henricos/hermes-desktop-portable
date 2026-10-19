# Using the package

## Where your data lives

Everything the app keeps (settings, gateway tokens, logs) lives in a `data` folder next to `HermesPortable.exe`. The app is built to leave `%APPDATA%`, `%LOCALAPPDATA%` and the registry alone, so deleting the unpacked folder uninstalls it; this is checked before each release (see [Testing a package](build-github-actions.md#testing-a-package)).

Gateway tokens are encrypted with Windows DPAPI, so a copied folder does not carry usable credentials to another Windows account: you enter the token again there.

## Upgrading

Keep your `data` folder. Either extract the new ZIP over the existing folder, or extract it to a new folder and move `data` into it. Explorer's "Extract All" creates a new folder named after the ZIP, so the second case is the usual one.

## Gateways

Your Hermes must expose its gateway to this machine, for example over your LAN, a VPN or Tailscale; see the upstream [documentation](https://hermes-agent.nousresearch.com/docs/) for gateway setup. You can add or change gateways later under **Settings → Gateways**; choose a remote gateway, never **Local** / **This device**.

## Avoiding a local install

This package does not block upstream's local-install paths; it avoids them as long as you do. Never choose:

- **Install Hermes locally** on the setup screen;
- **Repair** or **Use local gateway** on a connection-error screen;
- a **Local** / **This device** gateway in Settings.

Each of these downloads upstream's installer and sets up a full local Hermes (Python, uv, Git).
