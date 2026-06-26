param(
  [switch]$SkipMockBuild,
  [switch]$WithRealCore,
  [switch]$BuildDependencies,
  [switch]$SkipTerminalEmulator,
  [string]$ReportRoot = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
if ([string]::IsNullOrWhiteSpace($ReportRoot)) {
  $ReportRoot = Join-Path $tempRoot "tabssh_harmonyos_logs\local_checks"
}
$ReportRoot = [IO.Path]::GetFullPath($ReportRoot)
if (-not $ReportRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "ReportRoot must stay under $tempRoot"
}
New-Item -ItemType Directory -Path $ReportRoot -Force | Out-Null
$summaryPath = Join-Path $ReportRoot ("summary_{0}.md" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Name, [bool]$Pass, [string]$Detail) {
  $script:results.Add([PSCustomObject]@{ Name = $Name; Pass = $Pass; Detail = $Detail }) | Out-Null
  $mark = if ($Pass) { "PASS" } else { "FAIL" }
  Write-Host "[$mark] $Name - $Detail"
}

function Invoke-Step([string]$Name, [scriptblock]$Action) {
  try {
    & $Action
    Add-Result $Name $true "completed"
  } catch {
    Add-Result $Name $false $_.Exception.Message
    throw
  }
}

function Invoke-LoggedStep([string]$Name, [string]$FilePath, [string[]]$Arguments) {
  $safeName = $Name -replace "[^A-Za-z0-9_.-]", "_"
  $logPath = Join-Path $ReportRoot ("{0}_{1}.log" -f $safeName, (Get-Date -Format "yyyyMMdd_HHmmss"))
  Push-Location $projectRoot
  try {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $FilePath @Arguments *> $logPath
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
  } finally {
    $ErrorActionPreference = "Stop"
    Pop-Location
  }
  if ($exitCode -ne 0) {
    Get-Content -LiteralPath $logPath -Tail 120 -ErrorAction SilentlyContinue
    throw "$Name failed with exit code $exitCode. Log: $logPath"
  }
  Add-Result $Name $true "log: $logPath"
}

try {
  Invoke-LoggedStep "git-diff-check" "git.exe" @("diff", "--check")
  Invoke-LoggedStep "audit-project" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "audit_project.ps1"), "-ReportPath", (Join-Path $ReportRoot "project_audit_latest.md"))
  Invoke-LoggedStep "audit-connection-groups" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "audit_connection_groups.ps1"), "-ReportPath", (Join-Path $ReportRoot "connection_group_audit_latest.md"))

  if (-not $SkipTerminalEmulator) {
    Invoke-LoggedStep "terminal-emulator" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "test_terminal_emulator.ps1"))
  } else {
    Add-Result "terminal-emulator" $true "skipped by -SkipTerminalEmulator"
  }

  if (-not $SkipMockBuild) {
    Invoke-LoggedStep "mock-build" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "build_mock_hap.ps1"))
    Invoke-LoggedStep "mock-verify" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "verify_mock_hap.ps1"))
  } else {
    Add-Result "mock-build" $true "skipped by -SkipMockBuild"
    Add-Result "mock-verify" $true "skipped by -SkipMockBuild"
  }

  if ($WithRealCore) {
    if ($BuildDependencies) {
      Invoke-LoggedStep "real-dependencies" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "build_native_dependencies.ps1"))
    } else {
      Add-Result "real-dependencies" $true "skipped; expecting existing manifest"
    }
    Invoke-LoggedStep "real-build" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "build_real_hap.ps1"))
    Invoke-LoggedStep "real-verify" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $PSScriptRoot "verify_real_hap.ps1"))
  } else {
    Add-Result "real-build" $true "skipped; pass -WithRealCore to build real HAP"
    Add-Result "real-verify" $true "skipped; pass -WithRealCore to verify real HAP"
  }
} finally {
  $failed = @($results | Where-Object { -not $_.Pass })
  $lines = @(
    "# Local checks summary",
    "",
    "- Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')",
    "- Branch: $((git -C $projectRoot rev-parse --abbrev-ref HEAD 2>$null) -join '')",
    "- Commit: $((git -C $projectRoot rev-parse HEAD 2>$null) -join '')",
    "- Results: $($results.Count)",
    "- PASS: $($results.Count - $failed.Count)",
    "- FAIL: $($failed.Count)",
    "",
    "| Check | Result | Detail |",
    "|---|---|---|"
  )
  foreach ($item in $results) {
    $status = if ($item.Pass) { "PASS" } else { "FAIL" }
    $detail = ([string]$item.Detail).Replace("|", "`")
    $lines += "| $($item.Name) | $status | $detail |"
  }
  $lines += ""
  $lines += "This summary contains paths and hashes only. Do not paste credentials, server addresses, usernames, private keys, or raw device logs into committed reports."
  Set-Content -LiteralPath $summaryPath -Value $lines -Encoding UTF8
  Write-Host "Local check summary: $summaryPath"
}

if (@($results | Where-Object { -not $_.Pass }).Count -gt 0) {
  exit 1
}
