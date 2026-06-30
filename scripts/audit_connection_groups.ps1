param(
  [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
  $ReportPath = Join-Path $projectRoot "reports\connection_group_audit_latest.md"
}
$reportPath = [IO.Path]::GetFullPath($ReportPath)

$groupPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\ConnectionGroupPage.ets"
$indexPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\Index.ets"
$editPagePath = Join-Path $projectRoot "entry\src\main\ets\pages\ConnectionEditPage.ets"
$mainPagesPath = Join-Path $projectRoot "entry\src\main\resources\base\profile\main_pages.json"
$repositoryPath = Join-Path $projectRoot "entry\src\main\ets\common\storage\ProfileRepository.ets"

$groupPage = if (Test-Path -LiteralPath $groupPagePath) { Get-Content -LiteralPath $groupPagePath -Raw } else { "" }
$indexPage = if (Test-Path -LiteralPath $indexPagePath) { Get-Content -LiteralPath $indexPagePath -Raw } else { "" }
$editPage = if (Test-Path -LiteralPath $editPagePath) { Get-Content -LiteralPath $editPagePath -Raw } else { "" }
$mainPages = if (Test-Path -LiteralPath $mainPagesPath) { Get-Content -LiteralPath $mainPagesPath -Raw } else { "" }
$repository = if (Test-Path -LiteralPath $repositoryPath) { Get-Content -LiteralPath $repositoryPath -Raw } else { "" }
$allDocs = (Get-ChildItem -LiteralPath $projectRoot -Filter *.md -File -Recurse | Get-Content -Raw) -join "`n"

$checks = @(
  [PSCustomObject]@{ Name = "group-page-file"; Pass = Test-Path -LiteralPath $groupPagePath },
  [PSCustomObject]@{ Name = "group-page-route"; Pass = $mainPages.Contains('"pages/ConnectionGroupPage"') },
  [PSCustomObject]@{ Name = "group-repository-api"; Pass = $repository.Contains("listGroups") -and $repository.Contains("saveGroup") -and $repository.Contains("removeGroup") },
  [PSCustomObject]@{ Name = "group-add"; Pass = $groupPage.Contains("addGroup") -and $groupPage.Contains("createConnectionGroup") },
  [PSCustomObject]@{ Name = "group-rename"; Pass = $groupPage.Contains("startRename") -and $groupPage.Contains("saveRename") -and $groupPage.Contains("TextInput") },
  [PSCustomObject]@{ Name = "group-color"; Pass = $groupPage.Contains("cycleColor") -and $groupPage.Contains("palette") },
  [PSCustomObject]@{ Name = "group-sort-order"; Pass = $groupPage.Contains("moveGroup") -and $groupPage.Contains("sortOrder") },
  [PSCustomObject]@{ Name = "group-collapse"; Pass = $groupPage.Contains("toggleCollapsed") -and $groupPage.Contains("collapsed") },
  [PSCustomObject]@{ Name = "group-delete-guard"; Pass = $groupPage.Contains("group-default") -and $groupPage.Contains("countProfiles") },
  [PSCustomObject]@{ Name = "group-rdb-copy"; Pass = $groupPage.Contains("RDB") -and $groupPage.Contains("ProfileRepository") },
  [PSCustomObject]@{ Name = "group-rdb-persistence"; Pass = $repository.Contains("TABLE_GROUPS") -and $repository.Contains("persistGroup") -and $repository.Contains("readGroupsFromRdb") },
  [PSCustomObject]@{ Name = "index-group-entry"; Pass = $indexPage.Contains("openGroupPage") -and $indexPage.Contains("pages/ConnectionGroupPage") },
  [PSCustomObject]@{ Name = "index-group-filter"; Pass = $indexPage.Contains("selectedGroupId") -and $indexPage.Contains("filter.groupId") },
  [PSCustomObject]@{ Name = "edit-page-group-list"; Pass = $editPage.Contains("ProfileRepository.listGroups") -and $editPage.Contains("GroupChip") },
  [PSCustomObject]@{ Name = "edit-page-group-save"; Pass = $editPage.Contains("this.profile.groupId") -and $editPage.Contains("GroupChip") },
  [PSCustomObject]@{ Name = "group-docs"; Pass = $allDocs.Contains("ConnectionGroupPage") -and $allDocs.Contains("CONNECTION_GROUP_TEST.md") -and $allDocs.Contains("ProfileRepository") }
)

$failed = @($checks | Where-Object { -not $_.Pass })
$passCount = $checks.Count - $failed.Count
$lines = @(
  "# Connection group audit latest",
  "",
  "- Timestamp: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))",
  "- Checks: $($checks.Count)",
  "- PASS: $passCount",
  "- FAIL: $($failed.Count)",
  "- Scope: connection group route, homepage group entry/filter, edit-page group selector, RDB-backed repository API, page actions, documentation sync",
  ""
)
if ($failed.Count -gt 0) {
  $lines += "## Failures"
  $lines += ""
  $lines += $failed | ForEach-Object { "- $($_.Name)" }
} else {
  $lines += "Connection group static checks passed. This does not prove ArkUI/HAP compilation or device interaction."
}

New-Item -ItemType Directory -Path (Split-Path -Parent $reportPath) -Force | Out-Null
Set-Content -LiteralPath $reportPath -Value $lines -Encoding UTF8
Get-Content -LiteralPath $reportPath
if ($failed.Count -gt 0) { exit 1 }
