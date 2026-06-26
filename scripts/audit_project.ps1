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
  "docs\WORKSPACE_PATHS.md", "docs\BUILD_READY.md", "docs\BUILD_TEST.md", "docs\CORE.md", "docs\PROGRESS.md", "docs\PROICONS_ICONS.md", "docs\NEW_CHAT_PROMPT.md",
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
$moduleProfile = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\module.json5") -Raw
$mainPages = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\resources\base\profile\main_pages.json") -Raw
$cmake = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\CMakeLists.txt") -Raw
$repository = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\common\storage\ProfileRepository.ets") -Raw
$nativeHeader = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\native_ssh_core.h") -Raw
$realCore = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\native_ssh_libssh2.cpp") -Raw
$mockCore = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\native_ssh_mock.cpp") -Raw
$napi = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\cpp\napi_init.cpp") -Raw
$terminalPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\TerminalPage.ets") -Raw
$terminalManager = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\common\services\TerminalSessionManager.ets") -Raw
$terminalEmulator = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\common\terminal\TerminalEmulator.ets") -Raw
$sftpPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\SftpPage.ets") -Raw
$indexPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\Index.ets") -Raw
$groupPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\ConnectionGroupPage.ets"
$groupPage = if (Test-Path -LiteralPath $groupPagePath) { Get-Content -LiteralPath $groupPagePath -Raw } else { "" }
$forwardPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\PortForwardPage.ets") -Raw
$uiSource = (Get-ChildItem -LiteralPath (Join-Path $projectRoot "entry\src\main\ets") -Filter *.ets -File -Recurse |
  Get-Content -Raw -Encoding UTF8) -join "`n"
$forbiddenCharacterIconCodes = @(0x2039, 0x203A, 0x21BB, 0x2699, 0x25A3, 0x2261, 0x25A4, 0x26BF,
  0x25A6, 0x25B1, 0x25A1, 0x232F, 0x25F7, 0x25F0, 0x25CE, 0x25A0, 0x21E7, 0x221E,
  0x22EF, 0x2295, 0x24D8, 0x275D, 0x232B, 0x2263, 0x21E9, 0x21F5, 0x25D0, 0x2328,
  0x2191, 0x2193)
$hasForbiddenCharacterIcon = $uiSource -match '\p{So}'
foreach ($code in $forbiddenCharacterIconCodes) {
  if ($uiSource.Contains([string][char]$code)) {
    $hasForbiddenCharacterIcon = $true
    break
  }
}
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
  [PSCustomObject]@{ Name = "sftp-large-file-idle-timeout"; Pass = $realCore.Contains("local destination flush failed") -and $sftpPage.Contains("await fs.copyFile") -and -not $sftpPage.Contains("copyFileSync") },
  [PSCustomObject]@{ Name = "forward-real-local"; Pass = $realCore.Contains("libssh2_channel_direct_tcpip_ex") -and $realCore.Contains("CreateLoopbackListener") },
  [PSCustomObject]@{ Name = "forward-real-remote"; Pass = $realCore.Contains("libssh2_channel_forward_listen_ex") -and $realCore.Contains("libssh2_channel_forward_accept") },
  [PSCustomObject]@{ Name = "forward-real-socks5"; Pass = $realCore.Contains("HandleSocksClient") -and $realCore.Contains("request[3] == 0x04") },
  [PSCustomObject]@{ Name = "forward-disconnect-cleanup"; Pass = $realCore.Contains("StopForwardsForSession(sessionId)") -and $realCore.Contains("forward removed and resources released") },
  [PSCustomObject]@{ Name = "forward-async-napi"; Pass = $napi.Contains("ADD_LOCAL_FORWARD") -and $napi.Contains("ADD_REMOTE_FORWARD") -and $napi.Contains("ADD_DYNAMIC_FORWARD") -and $napi.Contains("REMOVE_FORWARD") },
  [PSCustomObject]@{ Name = "forward-mock-disabled"; Pass = $mockCore.Contains("Mock port forwarding is disabled") -and -not $mockCore.Contains('NextId("lfwd")') },
  [PSCustomObject]@{ Name = "forward-ui-three-types"; Pass = $forwardPage.Contains("本地 -L") -and $forwardPage.Contains("远程 -R") -and $forwardPage.Contains("SOCKS5 -D") -and $forwardPage.Contains("Mock Core 不会创建伪转发") },
  [PSCustomObject]@{ Name = "reconnect-backoff"; Pass = $terminalPage.Contains("5000 * Math.pow") -and $terminalPage.Contains("300000") -and $terminalPage.Contains("reconnectAttempt") },
  [PSCustomObject]@{ Name = "reconnect-intentional-close"; Pass = $terminalPage.Contains("intentionalClose") -and $terminalPage.Contains("cancelReconnectTimer") },
  [PSCustomObject]@{ Name = "reconnect-session-rebuild"; Pass = $terminalManager.Contains("reconnectTab") -and $terminalManager.Contains("NativeSshCore.disconnect(oldSessionId)") -and $terminalManager.Contains("NativeSshCore.createSession(profile)") },
  [PSCustomObject]@{ Name = "reconnect-eof-status"; Pass = $realCore.Contains("libssh2_channel_get_exit_status") -and $terminalManager.Contains("result.code === 0 ? 1008 : 1007") },
  [PSCustomObject]@{ Name = "shell-keepalive"; Pass = $realCore.Contains("libssh2_keepalive_config") -and $realCore.Contains("libssh2_keepalive_send") },
  [PSCustomObject]@{ Name = "reconnect-network-permission"; Pass = $moduleProfile.Contains("ohos.permission.GET_NETWORK_INFO") },
  [PSCustomObject]@{ Name = "reconnect-network-monitor"; Pass = $terminalPage.Contains("connection.createNetConnection") -and $terminalPage.Contains("connection.hasDefaultNet") -and $terminalPage.Contains("netAvailable") -and $terminalPage.Contains("netLost") },
  [PSCustomObject]@{ Name = "reconnect-network-fallback"; Pass = $terminalPage.Contains("300000") -and $terminalPage.Contains("networkPollTimer") },
  [PSCustomObject]@{ Name = "terminal-sgr-colors"; Pass = $terminalEmulator.Contains("applySgr") -and $terminalEmulator.Contains("xtermColor") -and $terminalEmulator.Contains("extendedColor") },
  [PSCustomObject]@{ Name = "terminal-alt-wide-scroll"; Pass = $terminalEmulator.Contains("setAlternateScreen") -and $terminalEmulator.Contains("characterWidth") -and $terminalEmulator.Contains("setScrollRegion") },
  [PSCustomObject]@{ Name = "terminal-protocol-responses"; Pass = $terminalEmulator.Contains("reportStatus") -and $terminalEmulator.Contains("drainResponses") -and $terminalEmulator.Contains("getTitle") },
  [PSCustomObject]@{ Name = "terminal-styled-ui"; Pass = $terminalPage.Contains("TerminalRenderRun") -and $terminalPage.Contains("Span(run.text)") -and $terminalPage.Contains("textBackgroundStyle") -and $terminalPage.Contains("copyOption") },
  [PSCustomObject]@{ Name = "terminal-pty-resize"; Pass = $terminalPage.Contains("updateTerminalSize") -and $terminalManager.Contains("NativeSshCore.resize") },
  [PSCustomObject]@{ Name = "terminal-application-modes"; Pass = $terminalPage.Contains("isApplicationCursorKeysEnabled") -and $terminalPage.Contains("isBracketedPasteEnabled") },
  [PSCustomObject]@{ Name = "connection-filter-ui"; Pass = $indexPage.Contains("搜索名称、主机、用户或备注") -and $indexPage.Contains("只看收藏") -and $indexPage.Contains("SORT_FAVORITE_FIRST") },
  [PSCustomObject]@{ Name = "connection-group-repository"; Pass = $repository.Contains("listGroups") -and $repository.Contains("saveGroup") -and $repository.Contains("removeGroup") },
  [PSCustomObject]@{ Name = "connection-group-page"; Pass = (Test-Path -LiteralPath $groupPagePath) -and $groupPage.Contains("struct ConnectionGroupPage") -and $groupPage.Contains("addGroup") -and $groupPage.Contains("removeGroup") },
  [PSCustomObject]@{ Name = "connection-group-route"; Pass = $mainPages.Contains('"pages/ConnectionGroupPage"') },
  [PSCustomObject]@{ Name = "connection-group-docs"; Pass = $allDocs.Contains("ConnectionGroupPage") -and $allDocs.Contains("连接分组页") -and $allDocs.Contains("BUILD_READY.md") },
  [PSCustomObject]@{ Name = "proicons-policy"; Pass = Test-Path -LiteralPath (Join-Path $projectRoot "docs\PROICONS_ICONS.md") },
  [PSCustomObject]@{ Name = "proicons-launcher"; Pass = $app.Contains('"icon": "$media:app_icon_proicons"') -and (Test-Path -LiteralPath (Join-Path $projectRoot "entry\src\main\resources\base\media\app_icon_proicons.svg")) },
  [PSCustomObject]@{ Name = "proicons-bottom-tabs"; Pass = $indexPage.Contains("settings_tune.svg") -and $indexPage.Contains("settings_network.svg") -and $indexPage.Contains("settings_monitor.svg") -and $indexPage.Contains("settings_person.svg") },
  [PSCustomObject]@{ Name = "no-old-custom-tab-icons"; Pass = -not (Get-ChildItem -LiteralPath (Join-Path $projectRoot "entry\src\main\resources\rawfile") -Filter "tab_*.svg" -File -ErrorAction SilentlyContinue) },
  [PSCustomObject]@{ Name = "no-character-ui-icons"; Pass = -not $hasForbiddenCharacterIcon },
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
  "- Scope: repository structure, bundle/ABI consistency, Mock boundary, credential hygiene, ProIcons policy, connection grouping, path policy, generated-file cleanup",
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
