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

function Remove-StageDirectory([string]$Path) {
  $resolved = [IO.Path]::GetFullPath($Path)
  if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove stage directory outside $tempRoot"
  }
  $lastError = $null
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
      Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction Stop
      return
    } catch {
      $lastError = $_
      if (-not (Test-Path -LiteralPath $resolved)) {
        return
      }
      Start-Sleep -Seconds 1
    }
  }
  $emptyRoot = Join-Path $tempRoot ("empty_stage_delete_{0}" -f ([guid]::NewGuid().ToString("N")))
  New-Item -ItemType Directory -Path $emptyRoot -Force | Out-Null
  try {
    & robocopy $emptyRoot $resolved /MIR /COPY:DAT /DCOPY:DA /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) {
      throw "robocopy cleanup failed with exit code $LASTEXITCODE"
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $resolved) {
      $remaining = Get-ChildItem -LiteralPath $resolved -Force -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($null -ne $remaining) {
        throw $lastError
      }
    }
  } finally {
    Remove-Item -LiteralPath $emptyRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

if (Test-Path -LiteralPath $StageRoot) {
  if (Get-ChildItem -LiteralPath $StageRoot -Filter *.apk -File -Recurse -ErrorAction SilentlyContinue) {
    throw "Refusing to replace a stage directory that contains APK files: $StageRoot"
  }
  Remove-StageDirectory $StageRoot
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
