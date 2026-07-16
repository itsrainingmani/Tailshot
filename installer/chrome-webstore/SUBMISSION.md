# Chrome Web Store Submission Checklist

This file is a dashboard handoff for Tailshot's Chrome Web Store listing.

## Upload Package

Upload this zip in the Package section:

```text
dist\chrome-webstore\tailshot-chrome-webstore-1.1.zip
```

Build all release artifacts with:

```powershell
.\installer\chrome-webstore\build-release.ps1
```

Validate the release artifacts before uploading:

```powershell
.\installer\chrome-webstore\validate-release.ps1 -Build
```

## Store Assets

Upload these listing assets:

```text
store-assets\chrome-webstore\screenshot-1280x800.png
store-assets\chrome-webstore\screenshot-device-picker-1280x800.png
store-assets\chrome-webstore\screenshot-local-transfer-1280x800.png
store-assets\chrome-webstore\small-promo-440x280.png
```

## Basic Listing

Name:

```text
Tailshot
```

Summary:

```text
Send browser images to your Tailscale devices with Taildrop.
```

Category:

```text
Productivity
```

Language:

```text
English
```

Website:

```text
https://github.com/itsrainingmani/Tailshot
```

Support URL:

```text
https://github.com/itsrainingmani/Tailshot/issues
```

Detailed description:

```text
Tailshot adds a right-click action for images in Chrome so you can send them to your own Tailscale devices with Taildrop.

After installing the companion native host, right-click an image, choose "Send with Tailscale", and pick a Taildrop-capable device. Tailshot uses the local Tailscale CLI on your computer; images are not uploaded to a Tailshot-operated server.

Requirements:
- Tailscale installed and signed in on this computer
- Taildrop enabled for your tailnet
- The Tailshot native host installed locally

Tailshot is intended for personal Tailscale setups and private device-to-device image transfer.

Tailshot is an independent project and is not affiliated with, endorsed by, or sponsored by Tailscale Inc.
```

## Single Purpose

```text
Tailshot sends an image selected by the user from the browser to one of the user's own Tailscale Taildrop devices.
```

## Permission Justifications

`contextMenus`:

```text
Adds the "Send with Tailscale" option when the user right-clicks an image.
```

`nativeMessaging`:

```text
Connects to the locally installed Tailshot native host so the extension can call the local Tailscale CLI for Taildrop transfer.
```

`optional_host_permissions: http://*/*, https://*/*`:

```text
Allows Tailshot to request access only to the origin of the specific image URL the user selected. Many web pages serve images from separate CDN domains, so activeTab alone is not enough to reliably fetch the selected image. Tailshot asks for host access at send time and fetches only the image chosen through the context menu.
```

## Privacy Practices

Suggested user data declarations:

- Website content: Yes
- Personally identifiable information: No
- Health information: No
- Financial and payment information: No
- Authentication information: No
- Personal communications: No
- Location: No
- Web history: No
- User activity: No

Data usage statement:

```text
Tailshot handles image URLs and image bytes only after the user explicitly selects "Send with Tailscale" from an image context menu and grants access to the selected image's origin when Chrome asks. The selected image is passed to the locally installed native host and then to the Tailscale CLI for Taildrop transfer. Tailshot does not sell data, use data for advertising, use data for creditworthiness, or send data to third-party analytics services.
```

Remote code:

```text
No remote code is used. All extension code is packaged in the submitted extension zip.
```

Privacy policy:

```text
Use this verified GitHub URL:

https://github.com/itsrainingmani/Tailshot/blob/main/PRIVACY.md
```

Only use the GitHub Pages privacy URL if Pages is enabled for the repository's `docs/` folder and the URL opens in a logged-out/private browser window:

```text
https://itsrainingmani.github.io/Tailshot/privacy.html
```

## Testing Instructions

```text
To test Tailshot, install Tailscale on the test machine, sign in, and enable Taildrop. Install the Tailshot native host using the Windows package from the project release artifacts, then right-click an image in Chrome and select "Send with Tailscale". The extension will list Taildrop-capable devices returned by `tailscale status --json`. Choose a device to send the selected image through Taildrop.
```

Detailed reviewer guide:

```text
installer/chrome-webstore/REVIEWER_TESTING.md
```

## Distribution

Recommended visibility for the first release:

```text
Unlisted
```

Use listed distribution later after the native-host installer and public documentation are polished.

## Dashboard Walkthrough

Use [DASHBOARD_STEPS.md](DASHBOARD_STEPS.md) as the short in-dashboard checklist.
