param(
  [switch]$IncludeExternalBuild,
  [switch]$BuildOnly
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
$projectName = Split-Path -Leaf $projectRoot

function Remove-ProjectGeneratedPath([string]$Path, [string]$AllowedRoot) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $full = [IO.Path]::GetFullPath($Path)
  $root = [IO.Path]::GetFullPath($AllowedRoot)
  if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clean outside allowed root: $full"
  }
  $item = Get-Item -LiteralPath $full -Force
  $containsApk = if ($item.PSIsContainer) {
    [bool](Get-ChildItem -LiteralPath $full -Filter *.apk -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1)
  } else {
    $item.Extension -ieq ".apk"
  }
  if ($containsApk) {
    throw "Refusing to clean a path containing APK files: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
  Write-Host "Removed $full"
}

$repoTargets = if ($BuildOnly) {
  @("build", "entry\build", "entry\.cxx")
} else {
  @(
    ".appanalyzer", ".codeartsdoer", ".hvigor", ".hvigor_home", ".idea", ".vscode",
    "build", "entry\build", "entry\.cxx", "entry\.preview", "oh_modules", "entry\oh_modules", "node_modules"
  )
}
foreach ($relative in $repoTargets) {
  Remove-ProjectGeneratedPath (Join-Path $projectRoot $relative) $projectRoot
}
Get-ChildItem -LiteralPath $projectRoot -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -in @(".dmp", ".log", ".tmp") } |
  ForEach-Object { Remove-ProjectGeneratedPath $_.FullName $projectRoot }

if ($IncludeExternalBuild) {
  foreach ($path in @(
    (Join-Path $tempRoot "harmonyos_stage\$projectName"),
    (Join-Path $tempRoot "harmonyos_build\$projectName"),
    (Join-Path $tempRoot "tabssh_harmonyos_logs")
  )) {
    Remove-ProjectGeneratedPath $path $tempRoot
  }
}

Write-Host "TabSSH project cleanup complete. Shared APKs and unrelated 99_Temp paths were not touched."
