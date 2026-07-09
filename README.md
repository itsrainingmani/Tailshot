# Tailshot - Tailscale image sender

Tailshot is a browser extension that sends images from a web page to your own Tailscale devices using Taildrop.

## Features

- Right-click any image in the browser and send it with Taildrop
- Shows Taildrop-capable devices reported by Tailscale
- Marks devices that Tailscale currently reports as offline, while still allowing Taildrop to try the send
- Uses the Tailscale CLI's supported `tailscale file cp --name <file> - <device>:` flow from the native host
- Works best in Chrome, Edge, and other modern Chromium browsers; Firefox support requires native messaging setup with the extension ID in this manifest

## How It Works

1. The extension adds a context menu item for images.
2. Selecting the item opens Tailshot's device picker.
3. The background worker downloads the image and sends it to the native host.
4. The native host streams the image into `tailscale file cp`.
5. Tailscale sends the file with Taildrop.

Taildrop must be enabled in your tailnet. Tailscale currently limits Taildrop to devices you own, and both devices must be running Tailscale.

## Requirements

- Tailscale installed and logged in on the sending computer
- Taildrop enabled for the tailnet
- The Tailscale CLI available as `tailscale` on the native host's PATH
- A native messaging host manifest registered for your browser

## Install

### Windows Quick Install

Build or download `tailscale_sender_host.exe`, load or install the extension, then run the per-user installer with the extension ID shown by the browser:

```powershell
.\installer\windows\install.ps1 -ExtensionId YOUR_EXTENSION_ID
```

The script copies the native host to `%LOCALAPPDATA%\Programs\Tailshot`, writes the native messaging manifest, and registers Chrome and Edge under `HKCU`. No admin prompt or manual registry editing is required.

To create a distributable Windows zip:

```powershell
.\installer\windows\package.ps1
```

See [installer/windows/README.md](installer/windows/README.md) for the recommended Chrome Web Store or Edge Add-ons release flow.

### 1. Build or Download the Native Host

Build from source:

```bash
cd native-host
go build -o tailscale_sender_host -ldflags="-w -s" .
```

On Windows, build:

```powershell
cd native-host
go build -o tailscale_sender_host.exe -ldflags="-w -s" .
```

### 2. Register the Native Host

The native host name must be:

```text
com.bitandbang.tailscale_image_sender
```

#### Windows Manual Registration

The installer script above is preferred. If you want to register the native host manually, create a folder such as `C:\tailscale-image-sender`, copy `tailscale_sender_host.exe` into it, then create `nmh-manifest.json`:

```json
{
  "name": "com.bitandbang.tailscale_image_sender",
  "description": "Host for sending files via Tailscale.",
  "path": "C:\\tailscale-image-sender\\tailscale_sender_host.exe",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://YOUR_EXTENSION_ID/"
  ]
}
```

Register it for Chrome or Edge:

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.bitandbang.tailscale_image_sender]
@="C:\\tailscale-image-sender\\nmh-manifest.json"

[HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.bitandbang.tailscale_image_sender]
@="C:\\tailscale-image-sender\\nmh-manifest.json"
```

#### macOS

Copy the binary somewhere stable and make it executable:

```bash
mkdir -p "$HOME/Library/Application Support/tailscale-image-sender"
cp tailscale_sender_host "$HOME/Library/Application Support/tailscale-image-sender/tailscale_sender_host"
chmod +x "$HOME/Library/Application Support/tailscale-image-sender/tailscale_sender_host"
```

Create the browser native messaging manifest, for example for Chrome:

```bash
mkdir -p "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
cat > "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.bitandbang.tailscale_image_sender.json" << EOF
{
  "name": "com.bitandbang.tailscale_image_sender",
  "description": "Host for sending files via Tailscale.",
  "path": "$HOME/Library/Application Support/tailscale-image-sender/tailscale_sender_host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://YOUR_EXTENSION_ID/"
  ]
}
EOF
```

For Edge, use `~/Library/Application Support/Microsoft Edge/NativeMessagingHosts/`.

#### Linux

Copy the binary somewhere stable and make it executable:

```bash
mkdir -p ~/.local/share/tailscale-image-sender
cp tailscale_sender_host ~/.local/share/tailscale-image-sender/tailscale_sender_host
chmod +x ~/.local/share/tailscale-image-sender/tailscale_sender_host
```

Create the browser native messaging manifest, for example for Chrome:

```bash
mkdir -p ~/.config/google-chrome/NativeMessagingHosts
cat > ~/.config/google-chrome/NativeMessagingHosts/com.bitandbang.tailscale_image_sender.json << EOF
{
  "name": "com.bitandbang.tailscale_image_sender",
  "description": "Host for sending files via Tailscale.",
  "path": "$HOME/.local/share/tailscale-image-sender/tailscale_sender_host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://YOUR_EXTENSION_ID/"
  ]
}
EOF
```

For Chromium, use `~/.config/chromium/NativeMessagingHosts/`. For Edge, use `~/.config/microsoft-edge/NativeMessagingHosts/`.

### 3. Load the Extension

1. Open `chrome://extensions/` or `edge://extensions/`.
2. Enable developer mode.
3. Choose "Load unpacked".
4. Select this repository folder.
5. Copy the extension ID shown by the browser.
6. Replace `YOUR_EXTENSION_ID` in the native messaging manifest.

After editing the native messaging manifest, restart the browser.

## Usage

1. Right-click an image in the browser.
2. Select "Send with Tailscale".
3. Choose the destination device.

If a site blocks direct image fetches, Tailshot will show the HTTP or content-type error instead of sending an error page as a file.

## Browser Compatibility

The manifest includes both `background.service_worker` and `background.scripts`. Modern Chromium browsers use the service worker. Firefox can use the background script fallback, but Firefox native messaging manifests use `allowed_extensions` rather than Chromium's `allowed_origins`.

Firefox native host manifest example:

```json
{
  "name": "com.bitandbang.tailscale_image_sender",
  "description": "Host for sending files via Tailscale.",
  "path": "/absolute/path/to/tailscale_sender_host",
  "type": "stdio",
  "allowed_extensions": [
    "tailshot@bitandbang.com"
  ]
}
```

## Troubleshooting

### Failed to connect to native host

- Confirm the native host manifest is in the browser-specific native messaging directory.
- Confirm the manifest points to the real native host binary path.
- Confirm the extension ID matches `allowed_origins` for Chromium or `allowed_extensions` for Firefox.
- On macOS and Linux, confirm the native host binary is executable.

### No devices appear

- Run `tailscale status` and confirm Tailscale is connected.
- Confirm Taildrop is enabled for the tailnet.
- Confirm the target devices are yours and support Taildrop.
- Tagged devices and devices owned by other users cannot receive Taildrop files.

### Sends fail

- Run `tailscale file cp --targets` to confirm Tailscale sees Taildrop targets.
- Check that the `tailscale` command is available on the native host's PATH.
- Check `debug.log` next to the native host process working directory.

## Development

Format and test the native host:

```bash
cd native-host
go fmt ./...
go test ./...
```

Build release binaries with the desired target platform:

```bash
cd native-host
GOOS=linux GOARCH=amd64 go build -o tailscale_sender_host -ldflags="-w -s" .
GOOS=darwin GOARCH=arm64 go build -o tailscale_sender_host -ldflags="-w -s" .
GOOS=windows GOARCH=amd64 go build -o tailscale_sender_host.exe -ldflags="-w -s" .
```
