#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifest = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'manifest.json') | ConvertFrom-Json
$version = $manifest.version

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
Write-Host "  dist\tailshot-windows-$version.zip"
