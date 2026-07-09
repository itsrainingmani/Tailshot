#requires -Version 5.1
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string] $PublisherId,

	[Parameter(Mandatory = $true)]
	[string] $ExtensionId,

	[Parameter(Mandatory = $true)]
	[string] $ClientId,

	[Parameter(Mandatory = $true)]
	[string] $ClientSecret,

	[Parameter(Mandatory = $true)]
	[string] $RefreshToken,

	[string] $PackagePath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')) 'dist\chrome-webstore\tailshot-chrome-webstore-1.0.zip'),

	[switch] $Publish
)

$ErrorActionPreference = 'Stop'

if (!(Test-Path -LiteralPath $PackagePath)) {
	throw "Package not found: $PackagePath"
}

$tokenResponse = Invoke-RestMethod `
	-Method Post `
	-Uri 'https://oauth2.googleapis.com/token' `
	-Body @{
		client_id     = $ClientId
		client_secret = $ClientSecret
		refresh_token = $RefreshToken
		grant_type    = 'refresh_token'
	}

$token = $tokenResponse.access_token
if (!$token) {
	throw 'OAuth token response did not include an access_token.'
}

$headers = @{
	Authorization = "Bearer $token"
}

$uploadUri = "https://chromewebstore.googleapis.com/upload/v2/publishers/$PublisherId/items/$ExtensionId`:upload"
Write-Host "Uploading $PackagePath"
$uploadResponse = Invoke-RestMethod `
	-Method Post `
	-Uri $uploadUri `
	-Headers $headers `
	-InFile $PackagePath `
	-ContentType 'application/zip'

Write-Host 'Upload response:'
$uploadResponse | ConvertTo-Json -Depth 8

if ($Publish) {
	$publishUri = "https://chromewebstore.googleapis.com/v2/publishers/$PublisherId/items/$ExtensionId`:publish"
	Write-Host 'Submitting item for review.'
	$publishResponse = Invoke-RestMethod `
		-Method Post `
		-Uri $publishUri `
		-Headers $headers

	Write-Host 'Publish response:'
	$publishResponse | ConvertTo-Json -Depth 8
}
