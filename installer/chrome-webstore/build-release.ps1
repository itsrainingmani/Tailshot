#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

Push-Location $RepoRoot
try {
	& .\icons\create-icons.ps1
	& .\store-assets\chrome-webstore\create-assets.ps1
	& .\installer\chrome-webstore\package.ps1
	& .\installer\windows\package.ps1
} finally {
	Pop-Location
}

Write-Host ''
Write-Host 'Chrome Web Store release artifacts are ready:'
Write-Host '  dist\chrome-webstore\tailshot-chrome-webstore-1.0.zip'
Write-Host '  store-assets\chrome-webstore\screenshot-1280x800.png'
Write-Host '  store-assets\chrome-webstore\screenshot-device-picker-1280x800.png'
Write-Host '  store-assets\chrome-webstore\screenshot-local-transfer-1280x800.png'
Write-Host '  store-assets\chrome-webstore\small-promo-440x280.png'
Write-Host '  dist\tailshot-windows-1.0.zip'
