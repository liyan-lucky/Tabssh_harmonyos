param(
  [string]$StageRoot = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
$projectName = Split-Path -Leaf $projectRoot

if ([string]::IsNullOrWhiteSpace($StageRoot)) {
  $StageRoot = Join-Path $tempRoot "harmonyos_stage\$projectName"
}
$StageRoot = [IO.Path]::GetFullPath($StageRoot)
if (-not $StageRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "StageRoot must stay under $tempRoot"
}

if (Test-Path -LiteralPath $StageRoot) {
  if (Get-ChildItem -LiteralPath $StageRoot -Filter *.apk -File -Recurse -ErrorAction SilentlyContinue) {
    throw "Refusing to replace a stage directory that contains APK files: $StageRoot"
  }
  Remove-Item -LiteralPath $StageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $StageRoot -Force | Out-Null

$excludedDirs = @(
  ".git", ".agents", ".codex", ".appanalyzer", ".codeartsdoer", ".hvigor", ".hvigor_home", ".idea", ".vscode",
  "build", "node_modules", "oh_modules", "entry\build", "entry\.cxx", "entry\.preview", "entry\oh_modules"
)
$args = @($projectRoot, $StageRoot, "/E", "/COPY:DAT", "/DCOPY:DA", "/R:2", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/XD") +
  ($excludedDirs | ForEach-Object { Join-Path $projectRoot $_ }) +
  @("/XF", "*.dmp", "*.log", "*.tmp", "*.bak", "*.hap", "*.app", "*.hsp")

& robocopy @args | Out-Null
if ($LASTEXITCODE -gt 7) {
  throw "robocopy failed with exit code $LASTEXITCODE"
}

Write-Host "Staged clean project at $StageRoot"
Write-Output $StageRoot
