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
  "scripts\clean_project.ps1", "scripts\backup_project.ps1", "scripts\update_build_info.ps1",
  ".github\workflows\build-harmonyos.yml", ".github\workflows\test-harmonyos-sdk-token.yml",
  ".github\workflows\cleanup-releases.yml"
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
$connectionEditPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\ConnectionEditPage.ets") -Raw
$settingsPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\SettingsPage.ets") -Raw
$entryAbility = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\entryability\EntryAbility.ets") -Raw
$appSettingsPath = Join-Path $projectRoot "entry\src\main\ets\common\AppSettings.ets"
$appSettings = if (Test-Path -LiteralPath $appSettingsPath) { Get-Content -LiteralPath $appSettingsPath -Raw } else { "" }
$appThemePath = Join-Path $projectRoot "entry\src\main\ets\common\AppTheme.ets"
$appTheme = if (Test-Path -LiteralPath $appThemePath) { Get-Content -LiteralPath $appThemePath -Raw } else { "" }
$i18nPath = Join-Path $projectRoot "entry\src\main\ets\common\I18n.ets"
$i18n = if (Test-Path -LiteralPath $i18nPath) { Get-Content -LiteralPath $i18nPath -Raw } else { "" }
$buildInfoPath = Join-Path $projectRoot "entry\src\main\ets\common\BuildInfo.ets"
$buildInfo = if (Test-Path -LiteralPath $buildInfoPath) { Get-Content -LiteralPath $buildInfoPath -Raw } else { "" }
$releaseBuildWorkflowPath = Join-Path $projectRoot ".github\workflows\build-harmonyos.yml"
$releaseBuildWorkflow = if (Test-Path -LiteralPath $releaseBuildWorkflowPath) { Get-Content -LiteralPath $releaseBuildWorkflowPath -Raw } else { "" }
$releaseBuildWorkflowLines = $releaseBuildWorkflow -split "\r?\n"
$skipPackageVerifyEnvLine = @($releaseBuildWorkflowLines | Where-Object { $_.Contains("SKIP_PACKAGE_VERIFY:") })
$skipPackageVerifyIfLine = @($releaseBuildWorkflowLines | Where-Object { $_.Contains("if: ") -and $_.Contains("inputs[") -and $_.Contains(" != true") })
$releaseBuildVerifyToggleOk = ($skipPackageVerifyEnvLine.Count -gt 0) -and -not (($skipPackageVerifyEnvLine -join "`n").Contains("|| true")) -and ($skipPackageVerifyIfLine.Count -gt 0)
$sdkTokenWorkflowPath = Join-Path $projectRoot ".github\workflows\test-harmonyos-sdk-token.yml"
$sdkTokenWorkflow = if (Test-Path -LiteralPath $sdkTokenWorkflowPath) { Get-Content -LiteralPath $sdkTokenWorkflowPath -Raw } else { "" }
$cleanupWorkflowPath = Join-Path $projectRoot ".github\workflows\cleanup-releases.yml"
$cleanupWorkflow = if (Test-Path -LiteralPath $cleanupWorkflowPath) { Get-Content -LiteralPath $cleanupWorkflowPath -Raw } else { "" }
$auditLogModel = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\common\models\ConnectionAuditLog.ets") -Raw
$auditPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\AuditLogPage.ets"
$auditPage = if (Test-Path -LiteralPath $auditPagePath) { Get-Content -LiteralPath $auditPagePath -Raw } else { "" }
$historyPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\ConnectionHistoryPage.ets"
$historyPage = if (Test-Path -LiteralPath $historyPagePath) { Get-Content -LiteralPath $historyPagePath -Raw } else { "" }
$savedHostsPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\SavedHostsPage.ets"
$savedHostsPage = if (Test-Path -LiteralPath $savedHostsPagePath) { Get-Content -LiteralPath $savedHostsPagePath -Raw } else { "" }
$importExportPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\ConnectionImportExportPage.ets"
$importExportPage = if (Test-Path -LiteralPath $importExportPagePath) { Get-Content -LiteralPath $importExportPagePath -Raw } else { "" }
$importExportServicePath = Join-Path $projectRoot "entry\src\main\ets\common\services\ConnectionImportExportService.ets"
$importExportService = if (Test-Path -LiteralPath $importExportServicePath) { Get-Content -LiteralPath $importExportServicePath -Raw } else { "" }
$groupPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\ConnectionGroupPage.ets"
$groupPage = if (Test-Path -LiteralPath $groupPagePath) { Get-Content -LiteralPath $groupPagePath -Raw } else { "" }
$toolboxPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\ToolboxPage.ets"
$toolboxPage = if (Test-Path -LiteralPath $toolboxPagePath) { Get-Content -LiteralPath $toolboxPagePath -Raw } else { "" }
$terminalSettingsPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\TerminalSettingsPage.ets"
$terminalSettingsPage = if (Test-Path -LiteralPath $terminalSettingsPagePath) { Get-Content -LiteralPath $terminalSettingsPagePath -Raw } else { "" }
$aboutPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\AboutPage.ets"
$aboutPage = if (Test-Path -LiteralPath $aboutPagePath) { Get-Content -LiteralPath $aboutPagePath -Raw } else { "" }
$forwardPage = Get-Content -LiteralPath (Join-Path $projectRoot "entry\src\main\ets\pages\PortForwardPage.ets") -Raw
$fullscreenPageNames = @(
  "Index", "ConnectionEditPage", "ConnectionGroupPage", "SavedHostsPage", "AuditLogPage", "ConnectionHistoryPage", "ConnectionImportExportPage", "TerminalPage",
  "SftpPage", "PortForwardPage", "SettingsPage", "ToolboxPage", "TerminalSettingsPage", "AboutPage"
)
$fullscreenPagesHaveAvoidance = $true
foreach ($pageName in $fullscreenPageNames) {
  $pagePath = Join-Path $projectRoot "entry\src\main\ets\pages\$pageName.ets"
  if (-not (Test-Path -LiteralPath $pagePath)) {
    $fullscreenPagesHaveAvoidance = $false
    break
  }
  $pageSource = Get-Content -LiteralPath $pagePath -Raw
  if ($pageName -eq "Index") {
    if (-not ($pageSource.Contains("avoidStatusBarHeight") -and
        $pageSource.Contains("avoidNavigationBarHeight") -and
        $pageSource.Contains("HeaderOverlay") -and
        $pageSource.Contains("headerOverlayHeight") -and
        $pageSource.Contains("bottomNavBottomInset"))) {
      $fullscreenPagesHaveAvoidance = $false
      break
    }
  } else {
    if (-not ($pageSource.Contains("avoidStatusBarHeight") -and
        $pageSource.Contains("avoidNavigationBarHeight") -and
        $pageSource.Contains(".padding({ top: this.avoidStatusBarHeight"))) {
      $fullscreenPagesHaveAvoidance = $false
      break
    }
  }
}
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
$themeI18nSecondaryPages = @($auditPage, $historyPage, $importExportPage, $groupPage, $terminalSettingsPage, $aboutPage)
$themeI18nSecondaryPagesCovered = $true
foreach ($pageSource in $themeI18nSecondaryPages) {
  if (-not ($pageSource.Contains("AppTheme") -and
      $pageSource.Contains("I18n") -and
      $pageSource.Contains("@StorageLink('appThemeMode')") -and
      $pageSource.Contains("@StorageLink('appLanguage')"))) {
    $themeI18nSecondaryPagesCovered = $false
    break
  }
}
$themeI18nPrimaryPages = @($indexPage, $connectionEditPage, $terminalPage, $sftpPage, $forwardPage, $toolboxPage)
$themeI18nPrimaryPagesCovered = $true
foreach ($pageSource in $themeI18nPrimaryPages) {
  if (-not ($pageSource.Contains("AppTheme") -and
      $pageSource.Contains("I18n") -and
      $pageSource.Contains("@StorageLink('appThemeMode')") -and
      $pageSource.Contains("@StorageLink('appLanguage')"))) {
    $themeI18nPrimaryPagesCovered = $false
    break
  }
}
$checks += @(
  [PSCustomObject]@{ Name = "bundle-app"; Pass = $app.Contains('"bundleName": "com.open.tabssh"') },
  [PSCustomObject]@{ Name = "bundle-profile"; Pass = $profile.Contains('"bundleName": "com.open.tabssh"') },
  [PSCustomObject]@{ Name = "abi-arm64"; Pass = $entryProfile.Contains('"arm64-v8a"') },
  [PSCustomObject]@{ Name = "abi-x86_64"; Pass = $entryProfile.Contains('"x86_64"') },
  [PSCustomObject]@{ Name = "mock-explicit"; Pass = $cmake.Contains("native_ssh_mock.cpp") },
  [PSCustomObject]@{ Name = "real-core-explicit"; Pass = $cmake.Contains("native_ssh_libssh2.cpp") },
  [PSCustomObject]@{ Name = "hostkey-contract"; Pass = $nativeHeader.Contains("ConfirmHostKey") -and $realCore.Contains("kHostKeyChanged") },
  [PSCustomObject]@{ Name = "hostkey-ui-warning"; Pass = $terminalPage.Contains("showHostKeyConfirmation") -and $terminalPage.Contains("statusCode === 1002") -and $terminalPage.Contains("pendingHostKey") },
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
  [PSCustomObject]@{ Name = "forward-ui-three-types"; Pass = $forwardPage.Contains("addLocal") -and $forwardPage.Contains("addRemote") -and $forwardPage.Contains("addDynamic") -and $forwardPage.Contains("forward.socksD") -and $i18n.Contains("SOCKS5 -D") },
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
  [PSCustomObject]@{ Name = "connection-filter-ui"; Pass = $indexPage.Contains("searchKeyword") -and $indexPage.Contains("favoriteOnly") -and $indexPage.Contains("SORT_FAVORITE_FIRST") },
  [PSCustomObject]@{ Name = "connection-search-highlight"; Pass = $indexPage.Contains("HighlightedText") -and $indexPage.Contains("matchedField") -and $indexPage.Contains("textBackgroundStyle") },
  [PSCustomObject]@{ Name = "connection-bulk-actions"; Pass = $indexPage.Contains("bulkMode") -and $indexPage.Contains("applyBulkFavorite") -and $indexPage.Contains("applyBulkGroup") -and $indexPage.Contains("removeSelectedProfiles") },
  [PSCustomObject]@{ Name = "connection-group-index-entry"; Pass = $indexPage.Contains("openGroupPage") -and $indexPage.Contains("pages/ConnectionGroupPage") -and $indexPage.Contains("selectedGroupId") -and $indexPage.Contains("filter.groupId") },
  [PSCustomObject]@{ Name = "connection-group-repository"; Pass = $repository.Contains("listGroups") -and $repository.Contains("saveGroup") -and $repository.Contains("removeGroup") },
  [PSCustomObject]@{ Name = "connection-rdb-store"; Pass = $repository.Contains("@ohos.data.relationalStore") -and $repository.Contains("RDB_NAME") -and $repository.Contains("TABLE_PROFILES") -and $repository.Contains("TABLE_GROUPS") },
  [PSCustomObject]@{ Name = "connection-rdb-init"; Pass = $entryAbility.Contains("ProfileRepository.initialize") -and $repository.Contains("getRdbStoreSync") -and $repository.Contains("CREATE TABLE IF NOT EXISTS") },
  [PSCustomObject]@{ Name = "connection-rdb-sensitive-scrub"; Pass = $repository.Contains("stored.password = ''") -and $repository.Contains("stored.privateKeyPassphrase = ''") -and $repository.Contains("persistProfile") },
  [PSCustomObject]@{ Name = "connection-audit-model"; Pass = $auditLogModel.Contains("ConnectionAuditLog") -and $auditLogModel.Contains("AUDIT_CONNECT_SUCCESS") -and $auditLogModel.Contains("AUDIT_BULK_ACTION") },
  [PSCustomObject]@{ Name = "connection-audit-rdb"; Pass = $repository.Contains("TABLE_AUDIT_LOGS") -and $repository.Contains("listAuditLogs") -and $repository.Contains("recordAuditLog") -and $repository.Contains("readAuditLogsFromRdb") },
  [PSCustomObject]@{ Name = "connection-audit-page-route"; Pass = (Test-Path -LiteralPath $auditPagePath) -and $mainPages.Contains('"pages/AuditLogPage"') -and $indexPage.Contains("pages/AuditLogPage") },
  [PSCustomObject]@{ Name = "connection-audit-privacy-copy"; Pass = $auditPage.Contains("audit-summary-no-command-output-or-credentials") },
  [PSCustomObject]@{ Name = "connection-audit-export"; Pass = $auditPage.Contains("DocumentViewPicker") -and $auditPage.Contains("buildExportPayload") -and $auditPage.Contains("summary-only") -and $auditPage.Contains("opentabssh-audit-") -and $auditPage.Contains("verifySavedText") },
  [PSCustomObject]@{ Name = "connection-audit-filter"; Pass = $auditPage.Contains("AuditFilterOption") -and $auditPage.Contains("filteredLogs") -and $auditPage.Contains("selectedFilter") -and $auditPage.Contains("AUDIT_CONNECT_FAILURE") },
  [PSCustomObject]@{ Name = "connection-history-page-route"; Pass = (Test-Path -LiteralPath $historyPagePath) -and $mainPages.Contains('"pages/ConnectionHistoryPage"') -and $indexPage.Contains("pages/ConnectionHistoryPage") },
  [PSCustomObject]@{ Name = "connection-history-stats"; Pass = $historyPage.Contains("lastConnectedAt") -and $historyPage.Contains("connectionCount") -and $historyPage.Contains("lastErrorMessage") -and $historyPage.Contains("pages/TerminalPage") },
  [PSCustomObject]@{ Name = "saved-hosts-page-route"; Pass = (Test-Path -LiteralPath $savedHostsPagePath) -and $mainPages.Contains('"pages/SavedHostsPage"') -and $indexPage.Contains("pages/SavedHostsPage") },
  [PSCustomObject]@{ Name = "saved-hosts-management"; Pass = $savedHostsPage.Contains("struct SavedHostsPage") -and $savedHostsPage.Contains("ProfileRepository.listFiltered") -and $savedHostsPage.Contains("ConnectionEditPage") -and $savedHostsPage.Contains("TerminalPage") -and $savedHostsPage.Contains("AUDIT_BULK_ACTION") -and $savedHostsPage.Contains("profileRefreshToken") },
  [PSCustomObject]@{ Name = "connection-import-export-route"; Pass = (Test-Path -LiteralPath $importExportPagePath) -and $mainPages.Contains('"pages/ConnectionImportExportPage"') -and $indexPage.Contains("pages/ConnectionImportExportPage") },
  [PSCustomObject]@{ Name = "connection-import-export-service"; Pass = (Test-Path -LiteralPath $importExportServicePath) -and $importExportService.Contains("buildOpenSshConfig") -and $importExportService.Contains("parseOpenSshConfig") -and $importExportService.Contains("buildBackupJson") -and $importExportService.Contains("parseBackupJson") },
  [PSCustomObject]@{ Name = "connection-import-export-privacy"; Pass = $importExportService.Contains("no passwords") -and $importExportService.Contains("scrubProfile") -and $repository.Contains("importConnections") -and $repository.Contains("profileKeyExists") },
  [PSCustomObject]@{ Name = "connection-import-export-picker"; Pass = $importExportPage.Contains("DocumentViewPicker") -and $importExportPage.Contains("DocumentSaveOptions") -and $importExportPage.Contains("DocumentSelectOptions") -and $importExportPage.Contains("readSelectedText") -and $importExportPage.Contains("verifySavedText") },
  [PSCustomObject]@{ Name = "connection-group-page"; Pass = (Test-Path -LiteralPath $groupPagePath) -and $groupPage.Contains("struct ConnectionGroupPage") -and $groupPage.Contains("addGroup") -and $groupPage.Contains("removeGroup") },
  [PSCustomObject]@{ Name = "connection-group-route"; Pass = $mainPages.Contains('"pages/ConnectionGroupPage"') },
  [PSCustomObject]@{ Name = "connection-group-docs"; Pass = $allDocs.Contains("ConnectionGroupPage") -and $allDocs.Contains("CONNECTION_GROUP_TEST.md") -and $allDocs.Contains("BUILD_READY.md") },
  [PSCustomObject]@{ Name = "toolbox-page-route"; Pass = (Test-Path -LiteralPath $toolboxPagePath) -and $mainPages.Contains('"pages/ToolboxPage"') -and $indexPage.Contains("pages/ToolboxPage") },
  [PSCustomObject]@{ Name = "toolbox-proicons-rawfiles"; Pass = $toolboxPage.Contains("settings_network.svg") -and $toolboxPage.Contains("settings_palette.svg") -and -not $toolboxPage.Contains("<svg") },
  [PSCustomObject]@{ Name = "toolbox-pure-utilities"; Pass = $toolboxPage.Contains("formatJson") -and $toolboxPage.Contains("base64Encode") -and $toolboxPage.Contains("hashText") -and $toolboxPage.Contains("analyzeText") -and $toolboxPage.Contains("convertColor") -and $toolboxPage.Contains("convertUnit") -and $toolboxPage.Contains("showSystemInfo") },
  [PSCustomObject]@{ Name = "toolbox-network-utilities"; Pass = $toolboxPage.Contains("@ohos.net.socket") -and $toolboxPage.Contains("@ohos.net.connection") -and $toolboxPage.Contains("@ohos.net.http") -and $toolboxPage.Contains("runPortScan") -and $toolboxPage.Contains("runConnectivityTest") -and $toolboxPage.Contains("runSpeedTest") -and $toolboxPage.Contains("runUploadTest") -and $toolboxPage.Contains("analyzeNginxConfig") -and $toolboxPage.Contains("replace(/\{/g, '{\n')") -and $toolboxPage.Contains("proxy_pass") },
  [PSCustomObject]@{ Name = "toolbox-upload-speed"; Pass = $toolboxPage.Contains("http.RequestMethod.POST") -and $toolboxPage.Contains("buildUploadPayload") -and $toolboxPage.Contains("toolbox.uploadTest") -and $i18n.Contains("toolbox.uploadedBytes") },
  [PSCustomObject]@{ Name = "toolbox-public-ip"; Pass = $toolboxPage.Contains("queryPublicIp") -and $toolboxPage.Contains("extractIpAddress") -and $toolboxPage.Contains("https://api.ipify.org") -and $toolboxPage.Contains("https://ifconfig.me/ip") -and $i18n.Contains("toolbox.publicIpButton") },
  [PSCustomObject]@{ Name = "toolbox-subnet-discovery"; Pass = $toolboxPage.Contains("discoverSubnet") -and $toolboxPage.Contains("subnetCandidates") -and $toolboxPage.Contains("defaultIpv4Link") -and $toolboxPage.Contains("22, 80, 443") -and $i18n.Contains("toolbox.discoveryLimit") },
  [PSCustomObject]@{ Name = "toolbox-qr-matrix"; Pass = $toolboxPage.Contains("buildQrMatrix") -and $toolboxPage.Contains("reedSolomonRemainder") -and $toolboxPage.Contains("drawQrFinder") -and $toolboxPage.Contains("toolbox.qrMatrix") -and $i18n.Contains("toolbox.qrLegend") },
  [PSCustomObject]@{ Name = "toolbox-nginx-expanded"; Pass = $toolboxPage.Contains("expandNginxVariables") -and $toolboxPage.Contains("toolbox.nginxUpstreamServers") -and $toolboxPage.Contains("toolbox.nginxVariables") -and $toolboxPage.Contains("include: ") },
  [PSCustomObject]@{ Name = "toolbox-network-details"; Pass = $toolboxPage.Contains("formatRoutes") -and $toolboxPage.Contains("formatAddressFamily") -and $toolboxPage.Contains("toolbox.routes") },
  [PSCustomObject]@{ Name = "toolbox-icmp-equivalent"; Pass = $toolboxPage.Contains("runIcmpEquivalentTest") -and $toolboxPage.Contains("toolbox.icmpEquivalent") -and $toolboxPage.Contains("getConnectionProperties") -and $toolboxPage.Contains("probeTcp") -and $i18n.Contains("toolbox.icmpEquivalentPath") -and $i18n.Contains("ICMP raw socket") },
  [PSCustomObject]@{ Name = "workbench-toolbox-entry"; Pass = $indexPage.Contains("openToolboxPage") -and $indexPage.Contains("workbench.toolbox") -and -not $indexPage.Contains("type: 'hosts'") },
  [PSCustomObject]@{ Name = "workbench-host-options-only"; Pass = $indexPage.Contains("WorkbenchHostOptions") -and $indexPage.Contains("workbench.hostOptions") -and $indexPage.Contains("this.openSavedHostsPage()") -and $indexPage.Contains("pages/SavedHostsPage") -and -not $indexPage.Contains("workbench.addHostSub") -and -not $indexPage.Contains("workbench.recentHistoryCountSuffix") -and -not $indexPage.Contains("WorkbenchHostList") -and -not $indexPage.Contains("visibleWorkbenchHosts") },
  [PSCustomObject]@{ Name = "connections-recent-history"; Pass = $indexPage.Contains("recentProfiles") -and $indexPage.Contains(".slice(0, 10)") -and $indexPage.Contains("connections.recentHistory") -and -not $indexPage.Contains("this.ConnectionFilterCard()") -and -not $indexPage.Contains("this.ProfileRow(profile, index)") },
  [PSCustomObject]@{ Name = "workbench-profile-refresh"; Pass = $repository.Contains("notifyProfilesChanged") -and $repository.Contains("profileRefreshToken") -and $entryAbility.Contains("profileRefreshToken") -and $indexPage.Contains("onProfileRefreshTokenChanged") -and $savedHostsPage.Contains("onProfileRefreshTokenChanged") },
  [PSCustomObject]@{ Name = "theme-language-settings"; Pass = $settingsPage.Contains("AppSettingsRepository.setThemeMode") -and $settingsPage.Contains("AppSettingsRepository.setLanguage") -and $settingsPage.Contains("THEME_DARK") -and $settingsPage.Contains("LANG_EN") },
  [PSCustomObject]@{ Name = "theme-language-storage"; Pass = (Test-Path -LiteralPath $appSettingsPath) -and $appSettings.Contains("@ohos.data.preferences") -and $appSettings.Contains("APP_THEME_KEY") -and $appSettings.Contains("APP_LANGUAGE_KEY") -and $entryAbility.Contains("AppSettingsRepository.initialize") },
  [PSCustomObject]@{ Name = "language-system-follow"; Pass = $appSettings.Contains("@ohos.i18n") -and $appSettings.Contains("LANG_SYSTEM") -and $appSettings.Contains("getFirstPreferredLanguage") -and $appSettings.Contains("getPreferredLanguageList") -and $appSettings.Contains("resolveEffectiveLanguage") -and $i18n.Contains("resolveEffectiveLanguage(language)") -and $i18n.Contains("settings.languageSystemSub") -and $indexPage.Contains("LANG_SYSTEM") -and $indexPage.Contains("languageSummaryText") -and $settingsPage.Contains("LANG_SYSTEM") },
  [PSCustomObject]@{ Name = "theme-palettes"; Pass = (Test-Path -LiteralPath $appThemePath) -and $appTheme.Contains("pageBg") -and $appTheme.Contains("cardBg") -and $appTheme.Contains("#171A1E") -and $appTheme.Contains("#F0F4FA") -and $indexPage.Contains("AppTheme") -and $settingsPage.Contains("AppTheme") },
  [PSCustomObject]@{ Name = "theme-glass-chrome"; Pass = $appTheme.Contains("bottomNavBg") -and $appTheme.Contains("#20000000") -and $appTheme.Contains("#30FFFFFF") -and $indexPage.Contains("HeaderOverlay") -and $indexPage.Contains("BottomNavigation") -and $indexPage.Contains("linearGradient") -and $indexPage.Contains("#BB171A1E") -and $indexPage.Contains("#00F0F4FA") -and $indexPage.Contains("backgroundBlurStyle") -and $indexPage.Contains("bottomNavBottomInset") },
  [PSCustomObject]@{ Name = "header-compact-spacing"; Pass = $indexPage.Contains("headerStatusInset") -and $indexPage.Contains("return Math.max(24, this.avoidStatusBarHeight - 18)") -and $indexPage.Contains("return this.headerStatusInset() + 96") -and $indexPage.Contains("return Math.max(80, this.headerOverlayHeight() - 40)") -and $indexPage.Contains(".height(92)") -and $indexPage.Contains(".height(80)") },
  [PSCustomObject]@{ Name = "i18n-zh-en"; Pass = (Test-Path -LiteralPath $i18nPath) -and $i18n.Contains("const ZH_TEXT") -and $i18n.Contains("const EN_TEXT") -and $i18n.Contains("tab.workbench") -and $i18n.Contains("toolbox.title") },
  [PSCustomObject]@{ Name = "settings-tab-expanded"; Pass = $i18n.Contains("'tab.mine': '设置'") -and $indexPage.Contains("SettingsThemeRow") -and $indexPage.Contains("SettingsLanguageRow") -and -not $indexPage.Contains("mine.quote") -and -not $indexPage.Contains("pages/SettingsPage") },
  [PSCustomObject]@{ Name = "build-info-script"; Pass = (Test-Path -LiteralPath $buildInfoPath) -and $buildInfo.Contains("APP_VERSION_NAME") -and $buildInfo.Contains("BUILD_TIME") -and $aboutPage.Contains("APP_VERSION_NAME") -and $aboutPage.Contains("BUILD_TIME") -and (Get-Content -LiteralPath (Join-Path $projectRoot "scripts\build_mock_hap.ps1") -Raw).Contains("update_build_info.ps1") -and (Get-Content -LiteralPath (Join-Path $projectRoot "scripts\build_real_hap.ps1") -Raw).Contains("update_build_info.ps1") -and (Get-Content -LiteralPath (Join-Path $projectRoot "scripts\install_and_smoke.ps1") -Raw).Contains("build-info") },
  [PSCustomObject]@{ Name = "release-build-workflow"; Pass = $releaseBuildWorkflow.Contains("HARMONYOS_SDK_TOKEN") -and $releaseBuildWorkflow.Contains("linux_command_line_tool_6.1.1") -and $releaseBuildWorkflow.Contains("run_hvigor_with_sdk_patch.js") -and $releaseBuildWorkflow.Contains("BuildInfo") -and $releaseBuildWorkflow.Contains("version.env") -and $releaseBuildWorkflow.Contains("SHA256SUMS.txt") -and $releaseBuildWorkflow.Contains('unzip -t "$hap"') -and $releaseBuildWorkflow.Contains("arm64-v8a/.*libentry.so") -and $releaseBuildWorkflow.Contains("x86_64/.*libentry.so") -and $releaseBuildWorkflow.Contains("softprops/action-gh-release@v2") -and $releaseBuildWorkflow.Contains("actions/upload-artifact@v4") -and -not ($releaseBuildWorkflow.Contains("actions/checkout@v7") -or $releaseBuildWorkflow.Contains("actions/setup-java@v5") -or $releaseBuildWorkflow.Contains("actions/setup-node@v6") -or $releaseBuildWorkflow.Contains("actions/upload-artifact@v7")) },
  [PSCustomObject]@{ Name = "release-build-verify-toggle"; Pass = $releaseBuildVerifyToggleOk },
  [PSCustomObject]@{ Name = "sdk-token-workflow"; Pass = $sdkTokenWorkflow.Contains("HARMONYOS_SDK_TOKEN") -and $sdkTokenWorkflow.Contains("gh repo view") -and $sdkTokenWorkflow.Contains("gh release view") -and $sdkTokenWorkflow.Contains("linux-harmonyos-command-line-tool-full.7z") },
  [PSCustomObject]@{ Name = "cleanup-workflow-guard"; Pass = $cleanupWorkflow.Contains("DELETE_ALL_RELEASES") -and $cleanupWorkflow.Contains("permissions:") -and $cleanupWorkflow.Contains("actions: write") -and $cleanupWorkflow.Contains("gh release delete") -and $cleanupWorkflow.Contains("CURRENT_RUN_ID") },
  [PSCustomObject]@{ Name = "theme-i18n-primary-pages"; Pass = $themeI18nPrimaryPagesCovered -and $i18n.Contains("terminal.title") -and $i18n.Contains("sftp.title") -and $i18n.Contains("forward.title") -and $i18n.Contains("edit.titleNew") },
  [PSCustomObject]@{ Name = "theme-i18n-secondary-pages"; Pass = $themeI18nSecondaryPagesCovered -and $i18n.Contains("audit.title") -and $i18n.Contains("groups.title") -and $i18n.Contains("import.title") -and $i18n.Contains("history.title") -and $i18n.Contains("about.title") -and $i18n.Contains("terminalSettings.title") },
  [PSCustomObject]@{ Name = "proicons-policy"; Pass = Test-Path -LiteralPath (Join-Path $projectRoot "docs\PROICONS_ICONS.md") },
  [PSCustomObject]@{ Name = "proicons-launcher"; Pass = $app.Contains('"icon": "$media:app_icon_proicons"') -and (Test-Path -LiteralPath (Join-Path $projectRoot "entry\src\main\resources\base\media\app_icon_proicons.svg")) },
  [PSCustomObject]@{ Name = "proicons-bottom-tabs"; Pass = $indexPage.Contains("settings_tune.svg") -and $indexPage.Contains("settings_network.svg") -and $indexPage.Contains("settings_monitor.svg") -and $indexPage.Contains("settings_display.svg") },
  [PSCustomObject]@{ Name = "fullscreen-window-avoidance"; Pass = $entryAbility.Contains("setWindowLayoutFullScreen(true)") -and $entryAbility.Contains("getWindowAvoidArea") -and $entryAbility.Contains("avoidStatusBarHeight") -and ($indexPage.Contains("avoidNavigationBarHeight + 72") -or ($indexPage.Contains("contentBottomInset") -and $indexPage.Contains("bottomNavBottomInset") -and $indexPage.Contains("avoidNavigationBarHeight + 96"))) -and $fullscreenPagesHaveAvoidance },
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
  "- Scope: repository structure, bundle/ABI consistency, Mock boundary, credential hygiene, ProIcons policy, connection grouping, RDB persistence, audit log summary, path policy, generated-file cleanup",
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
