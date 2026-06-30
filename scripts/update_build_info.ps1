param(
  [string]$ProjectRoot = "",
  [string]$BuildTime = ""
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$appPath = Join-Path $ProjectRoot "AppScope\app.json5"
$buildInfoPath = Join-Path $ProjectRoot "entry\src\main\ets\common\BuildInfo.ets"
if (-not (Test-Path -LiteralPath $appPath)) {
  throw "AppScope app.json5 was not found: $appPath"
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $buildInfoPath))) {
  throw "BuildInfo target directory was not found: $(Split-Path -Parent $buildInfoPath)"
}

$appJson = Get-Content -LiteralPath $appPath -Raw
$versionNameMatch = [regex]::Match($appJson, '"versionName"\s*:\s*"([^"]+)"')
$versionCodeMatch = [regex]::Match($appJson, '"versionCode"\s*:\s*(\d+)')
if (-not $versionNameMatch.Success) {
  throw "versionName was not found in $appPath"
}
if (-not $versionCodeMatch.Success) {
  throw "versionCode was not found in $appPath"
}

$now = if ([string]::IsNullOrWhiteSpace($BuildTime)) { Get-Date } else { [DateTimeOffset]::Parse($BuildTime).DateTime }
$offsetNow = if ([string]::IsNullOrWhiteSpace($BuildTime)) { [DateTimeOffset]::Now } else { [DateTimeOffset]::Parse($BuildTime) }
$displayTime = $offsetNow.ToString("yyyy-MM-dd HH:mm:ss zzz")
$timestamp = $offsetNow.ToString("o")
$versionName = $versionNameMatch.Groups[1].Value.Replace("'", "\'")
$versionCode = [int]$versionCodeMatch.Groups[1].Value

$lines = @(
  "export const APP_VERSION_NAME: string = '$versionName';",
  "export const APP_VERSION_CODE: number = $versionCode;",
  "export const BUILD_TIME: string = '$displayTime';",
  "export const BUILD_TIMESTAMP: string = '$timestamp';"
)
Set-Content -LiteralPath $buildInfoPath -Value $lines -Encoding UTF8
Write-Host ("Updated BuildInfo: version {0} ({1}), build time {2}" -f $versionName, $versionCode, $displayTime)
