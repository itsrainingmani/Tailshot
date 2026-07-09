# Windows Packaging

Windows users do not need to edit the registry by hand. Chrome and Edge still require native messaging hosts to be registered in the registry, but `install.ps1` writes the per-user keys automatically.

## Recommended Release Flow

For the smoothest install experience:

1. Publish Tailshot to the Chrome Web Store, as listed or unlisted.
2. Optionally publish the same extension to Microsoft Edge Add-ons.
3. Use the published extension ID in the Windows installer.
4. Ship a zip or installer that contains:
   - `tailscale_sender_host.exe`
   - `install.ps1`
   - `uninstall.ps1`
   - a link to the extension store listing

The native host install can be fully automated per user. Browser extension installation still needs either a store install confirmation or enterprise policy.

## Developer Install

1. Build the native host:

   ```powershell
   cd native-host
   go build -o tailscale_sender_host.exe -ldflags="-w -s" .
   ```

2. Load the extension with developer mode in Chrome or Edge.
3. Copy the extension ID from the browser extension details page.
4. Run:

   ```powershell
   .\installer\windows\install.ps1 -ExtensionId YOUR_EXTENSION_ID
   ```

This installs the native host under `%LOCALAPPDATA%\Programs\Tailshot` and registers it for Chrome and Edge under `HKCU`.

## Release Zip

Build a zip package from the repository root:

```powershell
.\installer\windows\package.ps1
```

The zip is written to `dist\`. After extracting it, run:

```powershell
.\install.ps1 -ExtensionId YOUR_EXTENSION_ID
```

## Uninstall

```powershell
.\uninstall.ps1
```

## Why Not Install the Extension Silently?

Chrome on Windows does not allow normal applications to install a local CRX directly for consumer installs. External extension installation on Windows is intended for Chrome Web Store-hosted extensions and enterprise-managed deployments. A normal installer can:

- install the native host,
- register native messaging,
- open the Chrome Web Store or Edge Add-ons page,
- or, in managed environments, configure browser policy.

For personal distribution, an unlisted Chrome Web Store item plus this native-host installer is the least painful path.
