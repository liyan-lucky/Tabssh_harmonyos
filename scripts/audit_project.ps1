param(
  [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
  $ReportPath = Join-Path $projectRoot "reports\project_audit_latest.md"
}
$reportPath = [IO.Path]::GetFullPath($ReportPath)
$required = @(
  "README.md", "README_zh.md", "CHANGELOG.md", "LICENSE.md", "docs\README.md", "docs\AGENT_HANDOFF.md",
  "docs\WORKSPACE_PATHS.md", "docs\BUILD_TEST.md", "docs\CORE.md", "docs\PROGRESS.md", "docs\NEW_CHAT_PROMPT.md",
  "scripts\stage_project_for_build.ps1", "scripts\build_mock_hap.ps1", "scripts\verify_mock_hap.ps1",
  "scripts\build_native_dependencies.ps1", "scripts\build_real_hap.ps1", "scripts\verify_real_hap.ps1",
  "scripts\clean_project.ps1", "scripts\backup_project.ps1"
)
$checks = @()
foreach ($path in $required) {
  $checks += [PSCustomObject]@{ Name = "required:$path"; Pass = Test-Path -LiteralPath (Join-Path $projectRoot $path) }
}
$app = Get-Content -LiteralPath (Join-Path $projectRoot "AppScope\app.json5") -Raw
$profile = Get-Content -LiteralPath (Join-Path $projectRoot "build-profile.json5") -Raw
$entryProfile = Get-Content -LiteralPath (Join-Path $projectRoot "entry\build-profile.json5") -Raw
$cmake = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\CMakeLists.txt") -Raw
$repository = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\common\storage\ProfileRepository.ets") -Raw
$nativeHeader = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\native_ssh_core.h") -Raw
$realCore = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\native_ssh_libssh2.cpp") -Raw
$mockCore = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\native_ssh_mock.cpp") -Raw
$napi = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\napi_init.cpp") -Raw
$terminalPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\TerminalPage.ets") -Raw
$sftpPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\SftpPage.ets") -Raw
$forbiddenDemoPassword = "demo.password = " + "'password'"
$allDocs = (Get-ChildItem -LiteralPath $projectRoot -Filter *.md -File -Recurse | Get-Content -Raw) -join "`n"
$readmes = (Get-Content -LiteralPath (Join-Path $projectRoot "README.md") -Raw) + "`n" +
  (Get-Content -LiteralPath (Join-Path $projectRoot "README_zh.md") -Raw)
$checks += @(
  [PSCustomObject]@{ Name = "bundle-app"; Pass = $app.Contains('"bundleName": "com.open.tabssh"') },
  [PSCustomObject]@{ Name = "bundle-profile"; Pass = $profile.Contains('"bundleName": "com.open.tabssh"') },
  [PSCustomObject]@{ Name = "abi-arm64"; Pass = $entryProfile.Contains('"arm64-v8a"') },
  [PSCustomObject]@{ Name = "abi-x86_64"; Pass = $entryProfile.Contains('"x86_64"') },
  [PSCustomObject]@{ Name = "mock-explicit"; Pass = $cmake.Contains("native_ssh_mock.cpp") },
  [PSCustomObject]@{ Name = "real-core-explicit"; Pass = $cmake.Contains("native_ssh_libssh2.cpp") },
  [PSCustomObject]@{ Name = "hostkey-contract"; Pass = $nativeHeader.Contains("ConfirmHostKey") -and $realCore.Contains("kHostKeyChanged") },
  [PSCustomObject]@{ Name = "hostkey-ui-warning"; Pass = $terminalPage.Contains("服务器 HostKey 已变化") },
  [PSCustomObject]@{ Name = "sftp-write-core"; Pass = $realCore.Contains("SftpUpload") -and $realCore.Contains("SftpDownload") -and $realCore.Contains("SftpRename") -and $realCore.Contains("SftpChmod") },
  [PSCustomObject]@{ Name = "sftp-write-async-napi"; Pass = $napi.Contains('{"sftpUpload"') -and $napi.Contains('{"sftpDownload"') -and $napi.Contains("AsyncOperation::SFTP_REMOVE") },
  [PSCustomObject]@{ Name = "sftp-mock-disabled"; Pass = $mockCore.Contains("Mock SFTP upload is disabled") -and $mockCore.Contains("Mock SFTP remove is disabled") },
  [PSCustomObject]@{ Name = "sftp-private-temp-cleanup"; Pass = $sftpPage.Contains("context.cacheDir") -and $sftpPage.Contains("fs.unlinkSync") },
  [PSCustomObject]@{ Name = "no-demo-password"; Pass = -not $repository.Contains($forbiddenDemoPassword) },
  [PSCustomObject]@{ Name = "no-old-bundle-readme"; Pass = -not $readmes.Contains("io.github.opentabssh") },
  [PSCustomObject]@{ Name = "temp-rule"; Pass = $allDocs.Contains("99_Temp") },
  [PSCustomObject]@{ Name = "no-file-list"; Pass = -not (Test-Path -LiteralPath (Join-Path $projectRoot "FILE_LIST.txt")) },
  [PSCustomObject]@{ Name = "no-root-build"; Pass = -not (Test-Path -LiteralPath (Join-Path $projectRoot "build")) },
  [PSCustomObject]@{ Name = "no-entry-build"; Pass = -not (Test-Path -LiteralPath (Join-Path $projectRoot "entry\build")) },
  [PSCustomObject]@{ Name = "no-entry-cxx"; Pass = -not (Test-Path -LiteralPath (Join-Path $projectRoot "entry\.cxx")) },
  [PSCustomObject]@{ Name = "no-crash-dumps"; Pass = -not (Get-ChildItem -LiteralPath $projectRoot -Filter *.dmp -File -Force -ErrorAction SilentlyContinue) }
)

$failed = @($checks | Where-Object { -not $_.Pass })
$passPerRound = $checks.Count - $failed.Count
$lines = @(
  "# Project audit latest",
  "",
  "- Timestamp: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))",
  "- Checks: $($checks.Count)",
  "- PASS: $passPerRound",
  "- FAIL: $($failed.Count)",
  "- Scope: repository structure, bundle/ABI consistency, Mock boundary, credential hygiene, path policy, generated-file cleanup",
  ""
)
if ($failed.Count -gt 0) {
  $lines += "## Failures"
  $lines += ""
  $lines += $failed | ForEach-Object { "- $($_.Name)" }
} else {
  $lines += "All static baseline checks passed. This does not claim that real SSH functionality is implemented."
}
New-Item -ItemType Directory -Path (Split-Path -Parent $reportPath) -Force | Out-Null
Set-Content -LiteralPath $reportPath -Value $lines -Encoding UTF8
Get-Content -LiteralPath $reportPath
if ($failed.Count -gt 0) { exit 1 }
