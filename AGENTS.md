# Agent Instructions for Tailscale Image Sender

## Commands

- **Build Go native host**: `cd native-host && go build -o tailscale_sender_host.exe -ldflags="-w -s" .`
- **Cross-platform build**: `GOOS=linux GOARCH=amd64 go build -o tailscale_sender_host -ldflags="-w -s" .` (set GOOS/GOARCH as needed)
- **Test (native host)**: `cd native-host && go test ./...`
- **Format Go code**: `cd native-host && go fmt ./...`
- **Lint Go code**: `cd native-host && go vet ./...`
- **Extension development**: Load unpacked extension in browser developer mode

## Architecture

- **Extension**: Chrome extension (manifest v3) with background service worker and popup
- **Native Host**: Go binary communicating via native messaging protocol using stdin/stdout
- **Communication**: JSON messages with 4-byte length prefix (binary.LittleEndian)
- **Core flow**: Extension → Native Host → Tailscale CLI → Taildrop file transfer
- **Files**: `background.js` handles native messaging, `popup.js` handles UI, `main.go` is native host

## Code Style

- **Go**: Standard Go formatting, structured logging to `debug.log`, error wrapping with `fmt.Errorf`
- **JavaScript**: Camel case, async/await patterns, Chrome extension APIs, arrow functions
- **Error handling**: All errors logged and returned in response JSON with `success: bool` field
- **Naming**: Go uses PascalCase for exported, camelCase for unexported; JS uses camelCase
- **Constants**: Go uses UPPER_SNAKE_CASE, grouped in const blocks
