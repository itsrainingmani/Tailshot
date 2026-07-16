#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifest = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'manifest.json') | ConvertFrom-Json
$version = $manifest.version

# Icons and store assets are exported from the Tailshot Redesign design project
# and committed under icons/ and store-assets/ — they are not regenerated here.
Push-Location $RepoRoot
try {
	& .\installer\chrome-webstore\package.ps1
	& .\installer\windows\package.ps1
} finally {
	Pop-Location
}

Write-Host ''
Write-Host 'Chrome Web Store release artifacts are ready:'
Write-Host "  dist\chrome-webstore\tailshot-chrome-webstore-$version.zip"
Write-Host '  store-assets\chrome-webstore\screenshot-1280x800.png'
Write-Host '  store-assets\chrome-webstore\screenshot-device-picker-1280x800.png'
Write-Host '  store-assets\chrome-webstore\screenshot-local-transfer-1280x800.png'
Write-Host '  store-assets\chrome-webstore\small-promo-440x280.png'
Write-Host "  dist\tailshot-windows-$version.zip"
