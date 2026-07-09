#requires -Version 5.1
[CmdletBinding()]
param(
	[string] $OutputDir = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')) 'dist'),
	[string] $PackageName = 'tailshot-chrome-webstore'
)

$ErrorActionPreference = 'Stop'

function Write-Utf8NoBom {
	param(
		[Parameter(Mandatory = $true)]
		[string] $Path,

		[Parameter(Mandatory = $true)]
		[string] $Value
	)

	$encoding = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifestPath = Join-Path $RepoRoot 'manifest.json'
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$version = $manifest.version

$outputRoot = Join-Path $OutputDir 'chrome-webstore'
$stagingRoot = Join-Path $outputRoot "$PackageName-$version"
$zipPath = Join-Path $outputRoot "$PackageName-$version.zip"

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$resolvedOutput = (Resolve-Path -LiteralPath $outputRoot).Path
if (!$resolvedOutput.StartsWith((Join-Path $RepoRoot 'dist'), [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Refusing to package outside the repository dist directory: $resolvedOutput"
}

if (Test-Path -LiteralPath $stagingRoot) {
	Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $stagingRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stagingRoot 'icons') | Out-Null

foreach ($file in @('background.js', 'popup.html', 'popup.js')) {
	Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination $stagingRoot -Force
}

Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'icons') -Filter '*.png' |
	Copy-Item -Destination (Join-Path $stagingRoot 'icons') -Force

$chromeManifest = [ordered]@{
	manifest_version = 3
	name             = $manifest.name
	short_name       = $manifest.short_name
	version          = $manifest.version
	description      = $manifest.description
	homepage_url     = $manifest.homepage_url
	permissions      = @($manifest.permissions)
	optional_host_permissions = @($manifest.optional_host_permissions)
	background       = [ordered]@{
		service_worker = $manifest.background.service_worker
	}
	icons            = [ordered]@{
		'16'  = $manifest.icons.'16'
		'32'  = $manifest.icons.'32'
		'48'  = $manifest.icons.'48'
		'128' = $manifest.icons.'128'
	}
}

Write-Utf8NoBom -Path (Join-Path $stagingRoot 'manifest.json') -Value (($chromeManifest | ConvertTo-Json -Depth 6) + [Environment]::NewLine)

if (Test-Path -LiteralPath $zipPath) {
	Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $stagingRoot '*') -DestinationPath $zipPath
Write-Host "Created $zipPath"
