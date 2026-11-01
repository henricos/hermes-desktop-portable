# Using the package

## Where your data lives

Everything the app keeps (settings, gateway tokens, logs) lives in a `data` folder next to `HermesPortable.exe`. The app is built to leave `%APPDATA%`, `%LOCALAPPDATA%` and the registry alone, so deleting the unpacked folder uninstalls it; this is checked before each release (see [Testing a package](build-github-actions.md#testing-a-package)).

Gateway tokens are encrypted with Windows DPAPI, so a copied folder does not carry usable credentials to another Windows account: you enter the token again there.

## Upgrading

Keep your `data` folder. Either extract the new ZIP over the existing folder, or extract it to a new folder and move `data` into it. Explorer's "Extract All" creates a new folder named after the ZIP, so the second case is the usual one.

## Gateways

Your Hermes must expose its gateway to this machine, for example over your LAN, a VPN or Tailscale; see the upstream [documentation](https://hermes-agent.nousresearch.com/docs/) for gateway setup. You can add or change gateways later under **Settings → Gateways**.

Run the same Hermes version on the server as the package was built from: `v0.22.2-r1` needs Hermes `v0.22.2` (the **Built from** badge in the README shows the current one). Upgrade the server whenever you upgrade the package. The desktop and the gateway speak a protocol that changes between releases, and a mismatch fails on ordinary use, for example every prompt failing with `invalid params for prompt.submit: ... Extra inputs are not permitted` and a hint to run `hermes update`.

## No local install

The package cannot install Hermes on your machine. The setup screen only offers **Connect to existing Hermes**, and "This device" is not shown in the gateway list. A few upstream options that rely on a local Hermes are still visible: the **Local gateway** connection mode, the **This device** entry under **Settings → Gateways → Saved connections**, and **Repair** on a connection-error screen. Choosing one shows an error instead of downloading upstream's installer; switch back to your remote gateway.
