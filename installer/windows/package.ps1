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

Copy-Item -LiteralPath (Join-Path $RepoRoot 'icons') -Destination (Join-Path $stagingRoot 'icons') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'install.ps1') -Destination $stagingRoot -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'uninstall.ps1') -Destination $stagingRoot -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.md') -Destination (Join-Path $stagingRoot 'WINDOWS_INSTALL.md') -Force

if (Test-Path -LiteralPath $zipPath) {
	Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $stagingRoot '*') -DestinationPath $zipPath
Write-Host "Created $zipPath"
