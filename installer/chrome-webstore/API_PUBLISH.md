# Chrome Web Store API Publishing

The Chrome Web Store API can upload and publish packages, but it does not remove every manual step for a first-time item. The official docs require the Store Listing and Privacy tabs to be completed in the Developer Dashboard before a new item can be published.

Use the dashboard for:

- Creating the first item
- Filling Store Listing fields
- Filling Privacy fields
- Setting visibility and distribution
- Completing any developer account, payment, or review confirmations

Use the API helper after the item exists and has an extension ID.

## Prerequisites

1. Enable 2-Step Verification on the publishing Google account.
2. Enable the Chrome Web Store API in a Google Cloud project.
3. Configure an OAuth consent screen.
4. Create an OAuth client ID and secret.
5. Use OAuth Playground with this scope:

   ```text
   https://www.googleapis.com/auth/chromewebstore
   ```

6. Exchange the authorization code for a refresh token.
7. Find the publisher ID in the Chrome Web Store Developer Dashboard.

Reference: https://developer.chrome.com/docs/webstore/using-api

## Upload Package

Build and validate the package:

```powershell
.\installer\chrome-webstore\validate-release.ps1 -Build
```

Upload the package:

```powershell
.\installer\chrome-webstore\publish-api.ps1 `
  -PublisherId PUBLISHER_ID `
  -ExtensionId EXTENSION_ID `
  -ClientId CLIENT_ID `
  -ClientSecret CLIENT_SECRET `
  -RefreshToken REFRESH_TOKEN
```

## Upload and Submit for Review

Only use `-Publish` after the dashboard listing, privacy, distribution, and test instructions are ready.

```powershell
.\installer\chrome-webstore\publish-api.ps1 `
  -PublisherId PUBLISHER_ID `
  -ExtensionId EXTENSION_ID `
  -ClientId CLIENT_ID `
  -ClientSecret CLIENT_SECRET `
  -RefreshToken REFRESH_TOKEN `
  -Publish
```

## Secret Handling

Do not commit OAuth credentials, refresh tokens, access tokens, or client secrets. Pass them as command-line parameters only in a local terminal you trust, or adapt the script to read from local environment variables.
