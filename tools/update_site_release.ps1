param(
  [Parameter(Mandatory = $true)]
  [string]$SiteDir,

  [Parameter(Mandatory = $true)]
  [string]$SiteDownloadDir,

  [Parameter(Mandatory = $true)]
  [string]$ApkFileName,

  [Parameter(Mandatory = $true)]
  [string]$ApkLatestName,

  [Parameter(Mandatory = $true)]
  [string]$UpdateManifestName,

  [Parameter(Mandatory = $true)]
  [string]$AppVersion,

  [Parameter(Mandatory = $true)]
  [int]$AppBuildNumber,

  [Parameter(Mandatory = $true)]
  [string]$ApkVersion,

  [string]$PlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.catudy.app'
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$utf8Bom = [System.Text.UTF8Encoding]::new($true)

$manifestPath = Join-Path $SiteDownloadDir $UpdateManifestName
$manifest = [ordered]@{
  version = $AppVersion
  buildNumber = $AppBuildNumber
  playStoreUrl = $PlayStoreUrl
  releaseNotes = [ordered]@{
    tr = 'Yeni Catudy surumu Google Play uzerinden hazir.'
    en = 'A new Catudy version is ready on Google Play.'
  }
  publishedAt = (Get-Date).ToUniversalTime().ToString('o')
}
$json = $manifest | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText(
  $manifestPath,
  $json + [Environment]::NewLine,
  $utf8NoBom
)

$indexPath = Join-Path $SiteDir 'site\index.html'
$html = [IO.File]::ReadAllText($indexPath, $utf8Bom)
$versionLabel = "Google Play"

$html = [regex]::Replace(
  $html,
  'href="(?:https://catudy\.com/|\.\/)?downloads/catudy-android-demo-[^"]+\.apk"',
  "href=`"$PlayStoreUrl`""
)
$html = [regex]::Replace(
  $html,
  '\sdownload(?:="[^"]*")?(\s+data-i18n="downloadButton")',
  '$1'
)
$html = [regex]::Replace(
  $html,
  '<strong>v[^<]+</strong>',
  "<strong>$ApkVersion</strong>"
)
$html = [regex]::Replace(
  $html,
  'Android APK v\d+(?:\.\d+){1,3}',
  $versionLabel
)

[IO.File]::WriteAllText(
  $indexPath,
  $html,
  $utf8Bom
)

$scriptPath = Join-Path $SiteDir 'site\script.js'
if (Test-Path -LiteralPath $scriptPath) {
  $script = [IO.File]::ReadAllText($scriptPath, $utf8NoBom)
  $script = [regex]::Replace(
    $script,
    '("hero\.androidCta"\s*:\s*")Android APK v[^"]+(")',
    "`${1}$versionLabel`${2}"
  )
  $script = [regex]::Replace(
    $script,
    '("download\.androidTitle"\s*:\s*")Android APK v[^"]+(")',
    "`${1}$versionLabel`${2}"
  )
  [IO.File]::WriteAllText(
    $scriptPath,
    $script,
    $utf8NoBom
  )
}
