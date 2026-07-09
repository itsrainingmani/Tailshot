#requires -Version 5.1
[CmdletBinding()]
param(
	[ValidateSet('Chrome', 'Edge')]
	[string[]] $Browser = @('Chrome', 'Edge'),

	[string] $InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\Tailshot')
)

$ErrorActionPreference = 'Stop'

$HostName = 'com.bitandbang.tailscale_image_sender'
$registryKeys = @{
	Chrome = "HKCU:\Software\Google\Chrome\NativeMessagingHosts\$HostName"
	Edge   = "HKCU:\Software\Microsoft\Edge\NativeMessagingHosts\$HostName"
}

foreach ($browserName in $Browser) {
	$key = $registryKeys[$browserName]
	if (Test-Path -LiteralPath $key) {
		Remove-Item -LiteralPath $key -Recurse -Force
		Write-Host "Removed $browserName native messaging host registration."
	}
}

if (Test-Path -LiteralPath $InstallDir) {
	Remove-Item -LiteralPath $InstallDir -Recurse -Force
	Write-Host "Removed install directory: $InstallDir"
}

Write-Host 'Tailshot native host uninstalled.'
