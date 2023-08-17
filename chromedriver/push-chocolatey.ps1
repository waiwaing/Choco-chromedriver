﻿param(
	[Parameter(Mandatory=$true)]
	[String]
	$apiKey,
	[Parameter(Mandatory=$true)]
	[String]
	$versionNumber,
	[Parameter(Mandatory=$false)]
	[String]
	$chocoMinorVersionNumber
)

$ErrorActionPreference = "Stop"

pushd ./chromedriver/tools

# Download the version
# URL of the JSON file
$jsonUrl = "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
# Fetch JSON content
$jsonContent = Invoke-RestMethod -Uri $jsonUrl
$url = $jsonContent.channels.Stable.downloads.chromedriver | Where-Object { $_.platform -eq $desiredPlatform } | Select-Object -ExpandProperty url
Write-Host "Downloading $url"
wget "$url" -OutFile chromedriver_win32.zip

# Get its checksum
$hash = Get-FileHash chromedriver_win32.zip
$hash = $hash.Hash
Write-Host "Hash is: $hash"
rm chromedriver_win32.zip

# Replace the checksum and version in the chocolateyinstall.ps1 file
$pwd = pwd
$content = [IO.File]::ReadAllText("$pwd\chocolateyinstall.template.ps1")
$content = $content.Replace("{CHECKSUM}", $hash)
$content = $content.Replace("{VERSION}", $versionNumber)

[IO.File]::WriteAllText("$pwd\chocolateyinstall.ps1", $content)
rm "$pwd\chocolateyinstall.template.ps1"

# Push to chocolatey.org
popd
pushd ./chromedriver/
rm *.nupkg
choco pack chromedriver.nuspec --version $versionNumber$chocoMinorVersionNumber
choco push --api-key=$apiKey
popd
