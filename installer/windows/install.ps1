#requires -Version 5.1
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidatePattern('^[a-p]{32}$')]
	[string[]] $ExtensionId,

	[ValidateSet('Chrome', 'Edge')]
	[string[]] $Browser = @('Chrome', 'Edge'),

	[string] $InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\Tailshot'),

	[string] $HostBinary = '',

	[switch] $SkipTailscaleCheck
)

$ErrorActionPreference = 'Stop'

$HostName = 'com.bitandbang.tailscale_image_sender'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir '..\..')

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

function Resolve-HostBinary {
	param([string] $ExplicitPath)

	if ($ExplicitPath) {
		if (!(Test-Path -LiteralPath $ExplicitPath)) {
			throw "Native host binary not found: $ExplicitPath"
		}
		return (Resolve-Path -LiteralPath $ExplicitPath).Path
	}

	$candidates = @(
		(Join-Path $ScriptDir 'tailscale_sender_host.exe'),
		(Join-Path $RepoRoot 'native-host\tailscale_sender_host.exe'),
		(Join-Path $RepoRoot 'native-host\tailscale_sender_host_windows_amd64.exe')
	)

	foreach ($candidate in $candidates) {
		if (Test-Path -LiteralPath $candidate) {
			return (Resolve-Path -LiteralPath $candidate).Path
		}
	}

	throw "Native host binary not found. Build it with: cd native-host; go build -o tailscale_sender_host.exe -ldflags='-w -s' ."
}

if (!$SkipTailscaleCheck -and !(Get-Command tailscale -ErrorAction SilentlyContinue)) {
	Write-Warning 'tailscale.exe was not found on PATH. Tailshot can still install, but sends will fail until the Tailscale CLI is available.'
}

$sourceHost = Resolve-HostBinary -ExplicitPath $HostBinary
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$installedHost = Join-Path $InstallDir 'tailscale_sender_host.exe'
Copy-Item -LiteralPath $sourceHost -Destination $installedHost -Force

$manifestPath = Join-Path $InstallDir "$HostName.json"
$allowedOrigins = @($ExtensionId | Sort-Object -Unique | ForEach-Object { "chrome-extension://$_/" })

$manifest = [ordered]@{
	name            = $HostName
	description     = 'Host for sending files via Tailscale.'
	path            = $installedHost
	type            = 'stdio'
	allowed_origins = $allowedOrigins
}

Write-Utf8NoBom -Path $manifestPath -Value (($manifest | ConvertTo-Json -Depth 4) + [Environment]::NewLine)

$registryKeys = @{
	Chrome = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName"
	Edge   = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$HostName"
}

foreach ($browserName in $Browser) {
	$key = $registryKeys[$browserName]
	New-Item -Path $key -Force | Out-Null
	Set-Item -Path $key -Value $manifestPath
	Write-Host "Registered $browserName native messaging host."
}

Write-Host ''
Write-Host 'Tailshot native host installed.'
Write-Host "Install directory: $InstallDir"
Write-Host "Native host manifest: $manifestPath"
Write-Host ''
Write-Host 'Restart your browser after installing or updating the native host.'
