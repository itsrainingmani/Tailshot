# Tailshot - A Tailscale based image sender

![vibecoded](https://img.shields.io/badge/vibe_coded-100%25-green?logo=claude)

A browser extension that allows you to send images between Tailscale devices using Taildrop.

## Features

- Send images from your browser to any online Tailscale device
- Supports drag-and-drop, copy-paste, and file selection
- Shows device status with OS-specific icons
- Works with Chrome, Edge, and other Chromium-based browsers

## Installation

### Prerequisites

1. **Tailscale** must be installed and running on your system
2. You must be logged into Tailscale
3. The devices you want to send files to must have Taildrop enabled

### Step 1: Download the Native Host Binary

Download the appropriate native host binary for your platform from the [latest release](https://github.com/itsrainingmani/tailscale_image_sender/releases/latest):

- **Windows**: `tailscale_sender_host_windows_amd64.exe`
- **macOS (Intel)**: `tailscale_sender_host_darwin_amd64`
- **macOS (Apple Silicon)**: `tailscale_sender_host_darwin_arm64`
- **Linux**: `tailscale_sender_host_linux_amd64`

### Step 2: Install the Native Host

#### Windows

1. Create a directory for the extension (e.g., `C:\tailscale-image-sender`)
2. Copy the downloaded `tailscale_sender_host_windows_amd64.exe` to this directory and rename it to `tailscale_sender_host.exe`
3. Create a file named `nmh-manifest.json` in the same directory with the following content:

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

4. Create a registry file `install.reg` with the following content (update the path):

```reg
Windows Registry Editor Version 5.00

; For Google Chrome
[HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.bitandbang.tailscale_image_sender]
@="C:\\tailscale-image-sender\\nmh-manifest.json"

; For Microsoft Edge
[HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.bitandbang.tailscale_image_sender]
@="C:\\tailscale-image-sender\\nmh-manifest.json"
```

5. Double-click `install.reg` to add the registry entry

#### macOS

1. Create the native messaging hosts directory (choose based on your browser):

```bash
# For Google Chrome
mkdir -p ~/Library/Application Support/Google/Chrome/NativeMessagingHosts/

# For Microsoft Edge
mkdir -p ~/Library/Application Support/Microsoft Edge/NativeMessagingHosts/

# For Chromium
mkdir -p ~/Library/Application Support/Chromium/NativeMessagingHosts/
```

2. Copy the downloaded binary to a suitable location:

```bash
mkdir -p ~/Library/Application Support/tailscale-image-sender
cp tailscale_sender_host_darwin_* ~/Library/Application Support/tailscale-image-sender/tailscale_sender_host
chmod +x ~/Library/Application Support/tailscale-image-sender/tailscale_sender_host
```

3. Create the manifest file (adjust the path based on your browser from step 1):

```bash
# Replace "Google/Chrome" with "Microsoft Edge" or "Chromium" as needed
cat > ~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.bitandbang.tailscale_image_sender.json << EOF
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

#### Linux

1. Create the native messaging hosts directory (choose based on your browser):

```bash
# For Google Chrome
mkdir -p ~/.config/google-chrome/NativeMessagingHosts/

# For Chromium
mkdir -p ~/.config/chromium/NativeMessagingHosts/

# For Microsoft Edge
mkdir -p ~/.config/microsoft-edge/NativeMessagingHosts/
```

2. Copy the downloaded binary to a suitable location:

```bash
mkdir -p ~/.local/share/tailscale-image-sender
cp tailscale_sender_host_linux_amd64 ~/.local/share/tailscale-image-sender/tailscale_sender_host
chmod +x ~/.local/share/tailscale-image-sender/tailscale_sender_host
```

3. Create the manifest file (adjust the path based on your browser from step 1):

```bash
# Replace "google-chrome" with "chromium" or "microsoft-edge" as needed
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

### Step 3: Install the Browser Extension

1. Clone this repository or download the source code
2. Open Chrome/Edge and navigate to `chrome://extensions/`
3. Enable "Developer mode" in the top right
4. Click "Load unpacked" and select the extension directory
5. Note the extension ID that appears

### Step 4: Update the Native Host Manifest

1. Replace `YOUR_EXTENSION_ID` in the `nmh-manifest.json` (Windows) or `com.bitandbang.tailscale_image_sender.json` (macOS/Linux) file with your actual extension ID
2. For Windows, you may need to update and re-run the registry file if you already installed it

### Step 5: Verify Installation

1. Click the extension icon in your browser
2. You should see a list of your online Tailscale devices
3. Try sending an image to verify everything works

## Usage

### Sending Images

1. Click the extension icon to open the popup
2. Select a device from the list
3. Send an image using one of these methods:
   - **Drag and drop**: Drag an image file onto the drop zone
   - **Copy and paste**: Copy an image (from a webpage or file) and paste with Ctrl+V/Cmd+V
   - **File selection**: Click "Select Image" to browse for a file

### Supported Formats

The extension supports common image formats including:

- JPEG/JPG
- PNG
- GIF
- WebP
- BMP

## Troubleshooting

### Extension shows "Failed to connect to native host"

1. Verify the native host binary is in the correct location
2. Check that the path in the manifest file is correct
3. Ensure the binary has execute permissions (macOS/Linux)
4. Check that the extension ID in the manifest matches your installed extension

### No devices showing up

1. Ensure Tailscale is running: `tailscale status`
2. Verify you're logged in to Tailscale
3. Check that other devices are online and have Taildrop enabled

### Debug logs

The native host creates a `debug.log` file in its directory. Check this file for error messages if you're experiencing issues.

## Building from Source

### Native Host

```bash
cd native-host
go build -o tailscale_sender_host -ldflags="-w -s" .
```

On Windows, the output will be `tailscale_sender_host.exe`.

To build for different platforms:

```bash
# Windows
GOOS=windows GOARCH=amd64 go build -o tailscale_sender_host.exe -ldflags="-w -s" .

# macOS (Intel)
GOOS=darwin GOARCH=amd64 go build -o tailscale_sender_host -ldflags="-w -s" .

# macOS (Apple Silicon)
GOOS=darwin GOARCH=arm64 go build -o tailscale_sender_host -ldflags="-w -s" .

# Linux
GOOS=linux GOARCH=amd64 go build -o tailscale_sender_host -ldflags="-w -s" .
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
