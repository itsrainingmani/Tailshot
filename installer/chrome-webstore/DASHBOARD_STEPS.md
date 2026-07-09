# Chrome Web Store Dashboard Steps

This is the shortest path through the dashboard once the release artifacts have been built.

For a copy-button companion page, open:

```text
installer\chrome-webstore\dashboard-handoff.html
```

## 1. Package

Upload:

```text
dist\chrome-webstore\tailshot-chrome-webstore-1.0.zip
```

## 2. Store Listing

Use the listing copy from:

```text
installer\chrome-webstore\SUBMISSION.md
```

Upload:

```text
store-assets\chrome-webstore\screenshot-1280x800.png
store-assets\chrome-webstore\small-promo-440x280.png
```

Suggested category:

```text
Productivity
```

Suggested visibility for the first release:

```text
Unlisted
```

Homepage URL:

```text
https://itsrainingmani.github.io/Tailshot/
```

Support URL:

```text
https://github.com/itsrainingmani/Tailshot/issues
```

## 3. Privacy

Use one of these privacy policy URL options after the changes are pushed:

```text
https://itsrainingmani.github.io/Tailshot/privacy.html
```

or:

```text
https://github.com/itsrainingmani/Tailshot/blob/main/PRIVACY.md
```

The GitHub Pages URL requires Pages to be enabled for the repository's `docs/` folder.

Data declarations:

- Website content: Yes
- Everything else listed in `SUBMISSION.md`: No

Remote code:

```text
No remote code is used. All extension code is packaged in the submitted extension zip.
```

## 4. Permissions

Use the permission justifications from `SUBMISSION.md`.

The most important one is optional host access:

```text
Allows Tailshot to request access only to the origin of the specific image URL the user selected. Many web pages serve images from separate CDN domains, so activeTab alone is not enough to reliably fetch the selected image. Tailshot asks for host access at send time and fetches only the image chosen through the context menu.
```

## 5. Review Notes

Attach or reference:

```text
installer\chrome-webstore\REVIEWER_TESTING.md
dist\tailshot-windows-1.0.zip
```

Reviewer note:

```text
Tailshot requires a local native messaging host because Chrome extensions cannot directly invoke the local Tailscale CLI. The Windows reviewer package includes the native host binary, installer script, and reviewer testing guide.
```

## 6. Submit

Before clicking submit, confirm:

- Package uploaded successfully
- Privacy policy URL opens in a logged-out/private browser window
- Store listing has at least one screenshot
- Distribution is set to unlisted for the first release
- Reviewer notes include the native-host testing instructions

## Optional API Uploads

After the item exists in the dashboard, future package uploads can be scripted with:

```text
installer\chrome-webstore\API_PUBLISH.md
```

The API does not replace the first dashboard setup for listing, privacy, account, and review confirmations.
