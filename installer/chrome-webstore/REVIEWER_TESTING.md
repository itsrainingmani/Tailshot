# Reviewer Testing Guide

Tailshot requires a local native messaging host because Chrome extensions cannot invoke the local Tailscale CLI directly.

## What the Extension Does

Tailshot adds a context menu item for images:

```text
Send with Tailscale
```

When the user selects that item, Tailshot downloads only the selected image URL and passes the image data to the locally installed native host. The native host streams the image into:

```text
tailscale file cp --name <filename> - <device>:
```

## Test Requirements

- Windows 10 or later
- Chrome
- Tailscale installed and signed in
- Taildrop enabled
- At least one Taildrop-capable device in the same tailnet

## Native Host Install for Review

1. Build or download `tailscale_sender_host.exe`.
2. Install the unpacked extension or the Chrome Web Store test build.
3. Copy the extension ID from Chrome.
4. Run the Windows installer:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1 -ExtensionId EXTENSION_ID -Browser Chrome
   ```

The installer:

- Copies `tailscale_sender_host.exe` to `%LOCALAPPDATA%\Programs\Tailshot`
- Creates the native messaging manifest
- Registers the host under `HKCU\Software\Google\Chrome\NativeMessagingHosts`
- Does not require administrator privileges

## Test Flow

1. Open any normal web page with an image.
2. Right-click an image.
3. Select "Send with Tailscale".
4. Choose a Taildrop-capable device.
5. Confirm the file appears on the destination device through Taildrop.

## Expected Permission Behavior

Tailshot requests:

- `contextMenus`, to add the image right-click command
- `nativeMessaging`, to talk to the local native host
- Optional host access for `http://*/*` and `https://*/*`, so it can request access to the selected image's origin at send time

Tailshot does not crawl pages or read arbitrary page contents. It asks for access only when the user sends an image and fetches only the image URL selected through the context menu.

## Troubleshooting

If the extension cannot connect to the native host:

- Confirm Chrome was restarted after native host installation.
- Confirm the extension ID in the native host manifest matches the installed extension.
- Confirm `tailscale status` works in PowerShell.
- Check `%LOCALAPPDATA%\Programs\Tailshot\debug.log`.
