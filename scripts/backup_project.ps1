param(
  [int]$Keep = 2
)

$ErrorActionPreference = "Stop"
if ($Keep -lt 1) { throw "Keep must be at least 1." }
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
$backupRoot = Join-Path $tempRoot "tabssh_harmonyos_backups"
$stageParent = Join-Path $tempRoot "tabssh_harmonyos_backup_stage"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stage = Join-Path $stageParent $stamp
$zip = Join-Path $backupRoot "tabssh_harmonyos_$stamp.zip"

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
New-Item -ItemType Directory -Path $stage -Force | Out-Null
$excludedDirs = @(
  ".git", ".appanalyzer", ".codeartsdoer", ".hvigor", ".hvigor_home", ".idea", ".vscode",
  "build", "node_modules", "oh_modules", "entry\build", "entry\.cxx", "entry\.preview", "entry\oh_modules", "signing"
)
$args = @($projectRoot, $stage, "/E", "/COPY:DAT", "/DCOPY:DA", "/R:2", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/XD") +
  ($excludedDirs | ForEach-Object { Join-Path $projectRoot $_ }) +
  @("/XF", "local.properties", "*.dmp", "*.log", "*.tmp", "*.bak", "*.hap", "*.app", "*.hsp", "*.so")
& robocopy @args | Out-Null
if ($LASTEXITCODE -gt 7) { throw "robocopy failed with exit code $LASTEXITCODE" }

Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal -Force
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash
Set-Content -LiteralPath ($zip + ".sha256") -Value "$hash  $([IO.Path]::GetFileName($zip))" -Encoding ASCII
Remove-Item -LiteralPath $stage -Recurse -Force

$old = Get-ChildItem -LiteralPath $backupRoot -Filter "tabssh_harmonyos_*.zip" -File |
  Sort-Object LastWriteTime -Descending | Select-Object -Skip $Keep
foreach ($item in $old) {
  Remove-Item -LiteralPath $item.FullName -Force
  $sidecar = $item.FullName + ".sha256"
  if (Test-Path -LiteralPath $sidecar) { Remove-Item -LiteralPath $sidecar -Force }
}

Write-Host "Backup: $zip"
Write-Host "SHA256: $hash"
