# Tailshot Privacy Policy

Tailshot is a browser extension for sending user-selected images to the user's own Tailscale devices through Taildrop.

## Data Tailshot Handles

Tailshot handles the following data only after the user right-clicks an image, chooses "Send with Tailscale", and grants access to the selected image's origin if Chrome asks:

- The selected image URL
- The selected image bytes
- The destination device name returned by the local Tailscale CLI

Tailshot does not collect browsing history, search history, account information, location, payment information, health information, personal communications, or authentication credentials.

## How Data Is Used

Tailshot uses the selected image URL to download that image in the extension background service worker. Tailshot requests host access at send time for the selected image's origin instead of requiring access to every site at install time. The image data is then sent to the locally installed Tailshot native host, which streams it into the local Tailscale CLI for Taildrop transfer.

Tailshot does not upload image data to Tailshot-operated servers. Tailshot does not sell data, use data for advertising, use data for creditworthiness, or share data with analytics providers.

## Local Native Host

Tailshot requires a companion native host installed on the user's computer. The native host receives image data from the extension and invokes `tailscale file cp` locally. The native host writes diagnostic messages to `debug.log` on the user's computer for troubleshooting.

## Third-Party Services

Tailshot depends on Tailscale being installed and configured by the user. File transfer is performed by Tailscale Taildrop according to the user's Tailscale configuration and Tailscale's own policies.

## Data Retention

Tailshot does not retain selected image data after the send operation completes. The native host streams image data to the Tailscale CLI and does not intentionally store image files on disk.

## Contact

For questions or issues, use the project's GitHub repository.
