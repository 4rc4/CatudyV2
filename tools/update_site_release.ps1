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
  [string]$ApkVersion
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$utf8Bom = [System.Text.UTF8Encoding]::new($true)

$manifestPath = Join-Path $SiteDownloadDir $UpdateManifestName
$manifest = [ordered]@{
  version = $AppVersion
  buildNumber = $AppBuildNumber
  apkUrl = "https://catudy.com/downloads/$ApkFileName"
  latestApkUrl = "https://catudy.com/downloads/$ApkLatestName"
  releaseNotes = [ordered]@{
    tr = 'Yeni Catudy surumu hazir.'
    en = 'A new Catudy version is ready.'
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

$html = [regex]::Replace(
  $html,
  'href="\./downloads/catudy-android-demo-[^"]+\.apk"',
  "href=`"./downloads/$ApkLatestName`"",
  1
)
$html = [regex]::Replace(
  $html,
  'download(?:="[^"]*")?(\s+data-i18n="downloadButton")',
  "download=`"$ApkFileName`"`$1",
  1
)
$html = [regex]::Replace(
  $html,
  '<strong>v[^<]+</strong>',
  "<strong>$ApkVersion</strong>",
  1
)

[IO.File]::WriteAllText(
  $indexPath,
  $html,
  $utf8Bom
)
