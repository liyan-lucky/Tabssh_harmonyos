param(
  [string]$HapPath = "",
  [string]$DeviceId = "",
  [string]$BundleName = "com.open.tabssh",
  [string]$AbilityName = "EntryAbility",
  [string]$ReportRoot = "",
  [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
if ([string]::IsNullOrWhiteSpace($ReportRoot)) {
  $ReportRoot = Join-Path $tempRoot "tabssh_harmonyos_logs\install_smoke"
}
$ReportRoot = [IO.Path]::GetFullPath($ReportRoot)
if (-not $ReportRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "ReportRoot must stay under $tempRoot"
}
New-Item -ItemType Directory -Path $ReportRoot -Force | Out-Null

if ([string]::IsNullOrWhiteSpace($HapPath)) {
  $defaultReal = Join-Path $tempRoot "harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap"
  $defaultMock = Join-Path $tempRoot "harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned.hap"
  if (Test-Path -LiteralPath $defaultReal) {
    $HapPath = $defaultReal
  } elseif (Test-Path -LiteralPath $defaultMock) {
    $HapPath = $defaultMock
  } else {
    throw "HapPath was not provided and no default HAP was found under $tempRoot"
  }
}
$HapPath = [IO.Path]::GetFullPath($HapPath)
if (-not $HapPath.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "HapPath must stay under $tempRoot to avoid installing an untracked artifact: $HapPath"
}
if (-not (Test-Path -LiteralPath $HapPath)) {
  throw "HAP not found: $HapPath"
}

function Resolve-Hdc() {
  $fromPath = Get-Command hdc.exe -ErrorAction SilentlyContinue
  if ($null -ne $fromPath) { return $fromPath.Source }
  $candidates = @(
    "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe",
    "C:\Program Files\Huawei\DevEco Studio\sdk\default\hmscore\toolchains\hdc.exe",
    "C:\Program Files\Huawei\DevEco Studio\tools\hdc\hdc.exe"
  )
  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  throw "hdc.exe was not found. Add DevEco toolchains to PATH or install DevEco Studio."
}

$hdc = Resolve-Hdc
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$rawLog = Join-Path $ReportRoot "install_smoke_$stamp.log"
$summaryPath = Join-Path $ReportRoot "summary_$stamp.md"
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Name, [bool]$Pass, [string]$Detail) {
  $script:results.Add([PSCustomObject]@{ Name = $Name; Pass = $Pass; Detail = $Detail }) | Out-Null
  $mark = if ($Pass) { "PASS" } else { "FAIL" }
  Write-Host "[$mark] $Name - $Detail"
}

function Invoke-Hdc([string]$Name, [string[]]$Arguments, [switch]$AllowFail) {
  $fullArgs = New-Object System.Collections.Generic.List[string]
  if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $fullArgs.Add("-t") | Out-Null
    $fullArgs.Add($DeviceId) | Out-Null
  }
  foreach ($arg in $Arguments) { $fullArgs.Add($arg) | Out-Null }
  "`n## $Name`n> hdc $($fullArgs -join ' ')" | Add-Content -LiteralPath $rawLog -Encoding UTF8
  $output = & $hdc @fullArgs 2>&1
  $exitCode = $LASTEXITCODE
  ($output -join "`n") | Add-Content -LiteralPath $rawLog -Encoding UTF8
  if ($exitCode -ne 0 -and -not $AllowFail) {
    throw "$Name failed with exit code $exitCode. See $rawLog"
  }
  return [PSCustomObject]@{ ExitCode = $exitCode; Output = ($output -join "`n") }
}

try {
  $targets = Invoke-Hdc "list-targets" @("list", "targets")
  Add-Result "hdc-targets" ($targets.Output.Trim().Length -gt 0) "targets listed"

  $hapHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $HapPath).Hash
  $hapItem = Get-Item -LiteralPath $HapPath
  Add-Result "hap-input" $true ("{0} bytes SHA256 {1}" -f $hapItem.Length, $hapHash)

  $buildInfoPath = Join-Path $projectRoot "entry\src\main\ets\common\BuildInfo.ets"
  if (Test-Path -LiteralPath $buildInfoPath) {
    $buildInfo = Get-Content -LiteralPath $buildInfoPath -Raw
    $versionName = [regex]::Match($buildInfo, "APP_VERSION_NAME:\s*string\s*=\s*'([^']*)'").Groups[1].Value
    $buildTime = [regex]::Match($buildInfo, "BUILD_TIME:\s*string\s*=\s*'([^']*)'").Groups[1].Value
    Add-Result "build-info" ($versionName.Length -gt 0 -and $buildTime.Length -gt 0) ("version {0}; build time {1}" -f $versionName, $buildTime)
  } else {
    Add-Result "build-info" $false "BuildInfo.ets missing"
  }

  $install = Invoke-Hdc "install" @("install", "-r", $HapPath)
  $installOk = $install.Output -match "success|finished|install bundle successfully"
  Add-Result "install" $installOk "install command completed; inspect raw log for exact device wording"

  $bundleDump = Invoke-Hdc "bundle-dump" @("shell", "bm", "dump", "-n", $BundleName) -AllowFail
  Add-Result "bundle-dump" ($bundleDump.ExitCode -eq 0 -and $bundleDump.Output.Length -gt 0) "bundle dump attempted"

  if (-not $NoLaunch) {
    $start = Invoke-Hdc "ability-start" @("shell", "aa", "start", "-a", $AbilityName, "-b", $BundleName) -AllowFail
    Add-Result "ability-start" ($start.ExitCode -eq 0 -or $start.Output -match "start ability successfully|success") "start attempted"
    Start-Sleep -Seconds 2
  } else {
    Add-Result "ability-start" $true "skipped by -NoLaunch"
  }

  $pidResult = Invoke-Hdc "pidof" @("shell", "pidof", $BundleName) -AllowFail
  $pidText = $pidResult.Output.Trim()
  $pidDetail = if ($pidText.Length -gt 0) { "pid: $pidText" } else { "pid unavailable" }
  Add-Result "pidof" ($pidResult.ExitCode -eq 0 -and $pidText.Length -gt 0) $pidDetail

  $hilog = Invoke-Hdc "hilog-tail" @("shell", "hilog", "-x", "-t", "200", "-m", "1000") -AllowFail
  $filtered = ($hilog.Output -split "`n") | Where-Object { $_ -match "com\.open\.tabssh|OpenTabSsh|FATAL|Fatal|cppcrash|jscrash|appfreeze|APP_INPUT_BLOCK" }
  $filteredPath = Join-Path $ReportRoot "hilog_filtered_$stamp.log"
  Set-Content -LiteralPath $filteredPath -Value $filtered -Encoding UTF8
  Add-Result "hilog-filter" $true ("filtered lines: {0}; file: {1}" -f @($filtered).Count, $filteredPath)

  $faultList = Invoke-Hdc "faultlogger-list" @("shell", "ls", "/data/log/faultlog/faultlogger") -AllowFail
  Add-Result "faultlogger-list" $true ("exitCode: {0}; unavailable may be normal on locked devices" -f $faultList.ExitCode)
} finally {
  $failed = @($results | Where-Object { -not $_.Pass })
  $lines = @(
    "# Install smoke summary",
    "",
    "- Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
    "- HAP: $HapPath",
    "- HAP SHA256: $((Get-FileHash -Algorithm SHA256 -LiteralPath $HapPath).Hash)",
    "- Bundle: $BundleName",
    "- DeviceId: $(if ([string]::IsNullOrWhiteSpace($DeviceId)) { '(default hdc target)' } else { $DeviceId })",
    "- Results: $($results.Count)",
    "- PASS: $($results.Count - $failed.Count)",
    "- FAIL: $($failed.Count)",
    "- Raw log: $rawLog",
    "",
    "| Check | Result | Detail |",
    "|---|---|---|"
  )
  foreach ($item in $results) {
    $status = if ($item.Pass) { "PASS" } else { "FAIL" }
    $detail = ([string]$item.Detail).Replace("|", "/")
    $lines += "| $($item.Name) | $status | $detail |"
  }
  $lines += ""
  $lines += "This smoke test only proves install/start/log collection. It does not prove SSH, SFTP, forwarding, signing, or release readiness. Do not commit raw logs if they contain secrets, server addresses, usernames, or private data."
  Set-Content -LiteralPath $summaryPath -Value $lines -Encoding UTF8
  Write-Host "Install smoke summary: $summaryPath"
}

if (@($results | Where-Object { -not $_.Pass }).Count -gt 0) {
  exit 1
}
