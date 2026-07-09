#requires -Version 5.1
[CmdletBinding()]
param(
	[switch] $Build
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ChromeZip = Join-Path $RepoRoot 'dist\chrome-webstore\tailshot-chrome-webstore-1.0.zip'
$WindowsZip = Join-Path $RepoRoot 'dist\tailshot-windows-1.0.zip'
$PromoImage = Join-Path $RepoRoot 'store-assets\chrome-webstore\small-promo-440x280.png'
$Screenshot = Join-Path $RepoRoot 'store-assets\chrome-webstore\screenshot-1280x800.png'
$DevicePickerScreenshot = Join-Path $RepoRoot 'store-assets\chrome-webstore\screenshot-device-picker-1280x800.png'
$LocalTransferScreenshot = Join-Path $RepoRoot 'store-assets\chrome-webstore\screenshot-local-transfer-1280x800.png'
$PrivacyHtml = Join-Path $RepoRoot 'docs\privacy.html'
$DocsIndex = Join-Path $RepoRoot 'docs\index.html'
$DocsInstall = Join-Path $RepoRoot 'docs\install.html'
$PrivacyMarkdown = Join-Path $RepoRoot 'PRIVACY.md'
$SubmissionGuide = Join-Path $RepoRoot 'installer\chrome-webstore\SUBMISSION.md'
$DashboardSteps = Join-Path $RepoRoot 'installer\chrome-webstore\DASHBOARD_STEPS.md'
$DashboardHandoff = Join-Path $RepoRoot 'installer\chrome-webstore\dashboard-handoff.html'
$ReviewerGuide = Join-Path $RepoRoot 'installer\chrome-webstore\REVIEWER_TESTING.md'
$ApiGuide = Join-Path $RepoRoot 'installer\chrome-webstore\API_PUBLISH.md'
$ApiScript = Join-Path $RepoRoot 'installer\chrome-webstore\publish-api.ps1'

function Assert-File {
	param([string] $Path)

	if (!(Test-Path -LiteralPath $Path)) {
		throw "Missing required file: $Path"
	}
}

function Assert-ImageSize {
	param(
		[string] $Path,
		[int] $Width,
		[int] $Height
	)

	Add-Type -AssemblyName System.Drawing
	$image = [System.Drawing.Image]::FromFile($Path)
	try {
		if ($image.Width -ne $Width -or $image.Height -ne $Height) {
			throw "Unexpected image size for $Path. Expected ${Width}x${Height}, got $($image.Width)x$($image.Height)."
		}
	} finally {
		$image.Dispose()
	}
}

function Get-ZipEntries {
	param([string] $Path)

	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
	try {
		return @($archive.Entries | ForEach-Object { $_.FullName } | Sort-Object)
	} finally {
		$archive.Dispose()
	}
}

function Assert-ZipEntries {
	param(
		[string] $Path,
		[string[]] $Expected
	)

	$actual = Get-ZipEntries -Path $Path
	$expectedSorted = @($Expected | Sort-Object)
	$missing = @($expectedSorted | Where-Object { $_ -notin $actual })
	$extra = @($actual | Where-Object { $_ -notin $expectedSorted })

	if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
		throw "Unexpected zip contents for $Path.`nMissing: $($missing -join ', ')`nExtra: $($extra -join ', ')"
	}
}

function Assert-JavaScriptSyntax {
	param([string] $Path)

	$node = Get-Command node -ErrorAction SilentlyContinue
	if (!$node) {
		Write-Warning 'node was not found; skipping JavaScript syntax checks.'
		return
	}

	& $node.Source --check $Path | Out-Null
	if ($LASTEXITCODE -ne 0) {
		throw "JavaScript syntax check failed: $Path"
	}
}

if ($Build) {
	Push-Location $RepoRoot
	try {
		& .\installer\chrome-webstore\build-release.ps1
	} finally {
		Pop-Location
	}
}

foreach ($path in @(
		$ChromeZip,
		$WindowsZip,
		$PromoImage,
		$Screenshot,
		$DevicePickerScreenshot,
		$LocalTransferScreenshot,
		$PrivacyHtml,
		$DocsIndex,
		$DocsInstall,
		$PrivacyMarkdown,
		$SubmissionGuide,
		$DashboardSteps,
		$DashboardHandoff,
		$ReviewerGuide,
		$ApiGuide,
		$ApiScript
	)) {
	Assert-File -Path $path
}

Assert-ImageSize -Path $PromoImage -Width 440 -Height 280
Assert-ImageSize -Path $Screenshot -Width 1280 -Height 800
Assert-ImageSize -Path $DevicePickerScreenshot -Width 1280 -Height 800
Assert-ImageSize -Path $LocalTransferScreenshot -Width 1280 -Height 800

Assert-ZipEntries -Path $ChromeZip -Expected @(
	'background.js',
	'icons/icon128.png',
	'icons/icon16.png',
	'icons/icon32.png',
	'icons/icon48.png',
	'manifest.json',
	'popup.html',
	'popup.js'
)

$chromeValidateDir = Join-Path $RepoRoot 'dist\chrome-webstore\validate'
if (Test-Path -LiteralPath $chromeValidateDir) {
	Remove-Item -LiteralPath $chromeValidateDir -Recurse -Force
}

Expand-Archive -LiteralPath $ChromeZip -DestinationPath $chromeValidateDir -Force
$manifest = Get-Content -Raw -LiteralPath (Join-Path $chromeValidateDir 'manifest.json') | ConvertFrom-Json

Assert-JavaScriptSyntax -Path (Join-Path $chromeValidateDir 'background.js')
Assert-JavaScriptSyntax -Path (Join-Path $chromeValidateDir 'popup.js')

if ($manifest.manifest_version -ne 3) {
	throw 'Chrome package manifest_version must be 3.'
}

if ($manifest.short_name -ne 'Tailshot') {
	throw 'Chrome package manifest short_name must be Tailshot.'
}

if ($manifest.homepage_url -ne 'https://github.com/itsrainingmani/Tailshot') {
	throw 'Chrome package manifest homepage_url is missing or unexpected.'
}

if ($manifest.host_permissions) {
	throw 'Chrome package must not request required host_permissions.'
}

$optionalHosts = @($manifest.optional_host_permissions)
foreach ($expectedOrigin in @('http://*/*', 'https://*/*')) {
	if ($expectedOrigin -notin $optionalHosts) {
		throw "Chrome package optional_host_permissions must include $expectedOrigin."
	}
}

if (!$manifest.background.service_worker) {
	throw 'Chrome package must use background.service_worker.'
}

if ($manifest.background.scripts) {
	throw 'Chrome package must not include background.scripts.'
}

if ($manifest.browser_specific_settings) {
	throw 'Chrome package must not include browser_specific_settings.'
}

Assert-ZipEntries -Path $WindowsZip -Expected @(
	'background.js',
	'DASHBOARD_STEPS.md',
	'icons/icon128.png',
	'icons/icon16.png',
	'icons/icon32.png',
	'icons/icon48.png',
	'install.ps1',
	'LICENSE',
	'manifest.json',
	'popup.html',
	'popup.js',
	'PRIVACY.md',
	'README.md',
	'REVIEWER_TESTING.md',
	'tailscale_sender_host.exe',
	'uninstall.ps1',
	'WINDOWS_INSTALL.md'
)

Write-Host 'Chrome Web Store release validation passed.'
