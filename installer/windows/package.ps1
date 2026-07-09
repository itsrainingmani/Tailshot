#requires -Version 5.1
[CmdletBinding()]
param(
	[string] $OutputDir = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')) 'dist'),
	[string] $PackageName = 'tailshot-windows'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifest = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'manifest.json') | ConvertFrom-Json
$version = $manifest.version

if (!$env:GOCACHE) {
	$env:GOCACHE = Join-Path $RepoRoot '.gocache'
}

$stagingRoot = Join-Path $OutputDir "$PackageName-$version"
$zipPath = Join-Path $OutputDir "$PackageName-$version.zip"

if (Test-Path -LiteralPath $stagingRoot) {
	Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $stagingRoot | Out-Null

$nativeHostDir = Join-Path $RepoRoot 'native-host'
$nativeHostOutput = Join-Path $stagingRoot 'tailscale_sender_host.exe'

Push-Location $nativeHostDir
try {
	go build -o $nativeHostOutput -ldflags='-w -s' .
} finally {
	Pop-Location
}

foreach ($file in @('manifest.json', 'background.js', 'popup.html', 'popup.js', 'README.md', 'LICENSE')) {
	Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination $stagingRoot -Force
}

New-Item -ItemType Directory -Force -Path (Join-Path $stagingRoot 'icons') | Out-Null
Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'icons') -Filter '*.png' |
	Copy-Item -Destination (Join-Path $stagingRoot 'icons') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'install.ps1') -Destination $stagingRoot -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'uninstall.ps1') -Destination $stagingRoot -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.md') -Destination (Join-Path $stagingRoot 'WINDOWS_INSTALL.md') -Force

$reviewerGuide = Join-Path $RepoRoot 'installer\chrome-webstore\REVIEWER_TESTING.md'
if (Test-Path -LiteralPath $reviewerGuide) {
	Copy-Item -LiteralPath $reviewerGuide -Destination (Join-Path $stagingRoot 'REVIEWER_TESTING.md') -Force
}

$dashboardSteps = Join-Path $RepoRoot 'installer\chrome-webstore\DASHBOARD_STEPS.md'
if (Test-Path -LiteralPath $dashboardSteps) {
	Copy-Item -LiteralPath $dashboardSteps -Destination (Join-Path $stagingRoot 'DASHBOARD_STEPS.md') -Force
}

$privacyPolicy = Join-Path $RepoRoot 'PRIVACY.md'
if (Test-Path -LiteralPath $privacyPolicy) {
	Copy-Item -LiteralPath $privacyPolicy -Destination (Join-Path $stagingRoot 'PRIVACY.md') -Force
}

if (Test-Path -LiteralPath $zipPath) {
	Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $stagingRoot '*') -DestinationPath $zipPath
Write-Host "Created $zipPath"
