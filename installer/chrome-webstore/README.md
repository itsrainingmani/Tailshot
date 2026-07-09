# Chrome Web Store Release

Use this flow for Chrome Web Store submissions. Do not upload the repository root directly; the root manifest includes cross-browser development fields that are useful locally but should not be in the Chrome Web Store package.

## Build the Upload Zip

From the repository root:

```powershell
.\installer\chrome-webstore\package.ps1
```

The upload package is written to:

```text
dist\chrome-webstore\tailshot-chrome-webstore-1.0.zip
```

To rebuild and validate all Chrome Web Store release artifacts:

```powershell
.\installer\chrome-webstore\validate-release.ps1 -Build
```

This package contains only:

- `manifest.json`
- `background.js`
- `popup.html`
- `popup.js`
- `icons/*.png`

The generated Chrome manifest keeps `background.service_worker` and removes Firefox-only or development-only fields.

## Store Listing Draft

For the full dashboard copy/paste checklist, use [SUBMISSION.md](SUBMISSION.md). For a short click-through checklist, use [DASHBOARD_STEPS.md](DASHBOARD_STEPS.md).

For a local copy-button companion page to keep beside the Chrome Web Store dashboard, open [dashboard-handoff.html](dashboard-handoff.html).

For API-based uploads after the Chrome Web Store item exists, use [API_PUBLISH.md](API_PUBLISH.md).

Suggested category: `Productivity`

Store listing images:

- `store-assets\chrome-webstore\screenshot-1280x800.png`
- `store-assets\chrome-webstore\screenshot-device-picker-1280x800.png`
- `store-assets\chrome-webstore\screenshot-local-transfer-1280x800.png`
- `store-assets\chrome-webstore\small-promo-440x280.png`

Short description:

```text
Send browser images to your Tailscale devices with Taildrop.
```

Detailed description:

```text
Tailshot adds a right-click action for images in Chrome so you can send them to your own Tailscale devices with Taildrop.

After installing the companion native host, right-click an image, choose "Send with Tailscale", and pick a Taildrop-capable device. Tailshot uses the local Tailscale CLI on your computer; images are not uploaded to a third-party service.

Requirements:
- Tailscale installed and signed in on this computer
- Taildrop enabled for your tailnet
- The Tailshot native host installed locally

Tailshot is intended for personal Tailscale setups and private device-to-device image transfer.
```

Single purpose:

```text
Tailshot sends an image selected from the browser to one of the user's own Tailscale Taildrop devices.
```

Permission justifications are maintained in [SUBMISSION.md](SUBMISSION.md). The Chrome package uses optional host permissions so Tailshot asks for access only to the selected image's origin at send time.

Remote code:

```text
No remote code is used. All extension code is packaged in the submitted extension zip.
```

Data usage:

```text
Tailshot handles image URLs and image bytes only after the user explicitly selects "Send with Tailscale" from an image context menu. The selected image is passed to the locally installed native host and then to the Tailscale CLI for Taildrop transfer. Tailshot does not sell data, use data for advertising, use data for creditworthiness, or send data to any third-party analytics service.
```

Suggested user data declarations:

- Website content: yes, because the extension downloads the user-selected image from a web page.
- Personally identifiable information: no.
- Health information: no.
- Financial and payment information: no.
- Authentication information: no.
- Personal communications: no.
- Location: no.
- Web history: no.
- User activity: no.

Test instructions:

```text
To test Tailshot, install Tailscale on the test machine, sign in, and enable Taildrop. Install the Tailshot native host from the linked repository instructions, then right-click an image in Chrome and select "Send with Tailscale". The extension will list Taildrop-capable devices returned by `tailscale status --json`.
```

## Manual Dashboard Steps

1. Open the Chrome Web Store Developer Dashboard.
2. Click "Add new item".
3. Upload `dist\chrome-webstore\tailshot-chrome-webstore-1.0.zip`.
4. Fill Store Listing, Privacy, Distribution, and Test instructions.
5. Upload the required listing images from `store-assets\chrome-webstore`.
6. Submit for review.

Chrome's dashboard requires the developer account owner to complete account, payment, privacy, and submission confirmations.

## Privacy Policy

Use [PRIVACY.md](../../PRIVACY.md) as the source text for the Chrome Web Store privacy policy. A GitHub Pages-ready HTML copy is available at [docs/privacy.html](../../docs/privacy.html). If GitHub Pages is enabled for the repository's `docs/` folder, use:

```text
https://itsrainingmani.github.io/Tailshot/privacy.html
```

Otherwise, use the GitHub URL for `PRIVACY.md` after pushing the release prep changes.

## Homepage and Support URLs

If GitHub Pages is enabled for the repository's `docs/` folder, use:

```text
Homepage: https://itsrainingmani.github.io/Tailshot/
Install help: https://itsrainingmani.github.io/Tailshot/install.html
Privacy: https://itsrainingmani.github.io/Tailshot/privacy.html
```

Use GitHub issues for support:

```text
https://github.com/itsrainingmani/Tailshot/issues
```

If GitHub Pages is not enabled yet, use the repository URL as the Chrome Web Store homepage:

```text
https://github.com/itsrainingmani/Tailshot
```

Use the pushed markdown privacy policy as the safest dashboard privacy URL:

```text
https://github.com/itsrainingmani/Tailshot/blob/main/PRIVACY.md
```
