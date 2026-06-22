param(
  [string]$StageRoot = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
$projectName = Split-Path -Leaf $projectRoot

if ([string]::IsNullOrWhiteSpace($StageRoot)) {
  $StageRoot = Join-Path $tempRoot "harmonyos_stage\$projectName"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path $tempRoot "harmonyos_build\$projectName"
}
$StageRoot = [IO.Path]::GetFullPath($StageRoot)
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
foreach ($path in @($StageRoot, $OutputRoot)) {
  if (-not $path.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Build paths must stay under $tempRoot"
  }
}

& (Join-Path $PSScriptRoot "stage_project_for_build.ps1") -StageRoot $StageRoot | Out-Host

$devecoRoot = "C:\Program Files\Huawei\DevEco Studio"
$hwsdkDir = if ($env:HARMONYOS_HWSDK_DIR) { $env:HARMONYOS_HWSDK_DIR } else { Join-Path $devecoRoot "sdk\default" }
$sdkDir = if ($env:HARMONYOS_SDK_DIR) { $env:HARMONYOS_SDK_DIR } else { Join-Path $hwsdkDir "openharmony" }
$nodeDir = if ($env:HARMONYOS_NODE_DIR) { $env:HARMONYOS_NODE_DIR } else { Join-Path $devecoRoot "tools\node" }
foreach ($path in @($hwsdkDir, $sdkDir, $nodeDir)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Required local SDK/tool path is missing: $path" }
}
function Escape-LocalPropertyPath([string]$Path) { return $Path.Replace("\", "\\") }
$localProperties = @(
  "sdk.dir=$(Escape-LocalPropertyPath $sdkDir)",
  "hwsdk.dir=$(Escape-LocalPropertyPath $hwsdkDir)",
  "npm.dir=$(Escape-LocalPropertyPath $nodeDir)"
)
Set-Content -LiteralPath (Join-Path $StageRoot "local.properties") -Value $localProperties -Encoding ASCII

$nodeExe = Join-Path $nodeDir "node.exe"
$runner = Join-Path $StageRoot "scripts\run_hvigor_with_sdk_patch.js"
if (-not (Test-Path -LiteralPath $nodeExe)) { throw "DevEco node.exe was not found: $nodeExe" }
if (-not (Test-Path -LiteralPath $runner)) { throw "Hvigor compatibility runner was not staged: $runner" }
$env:DEVECO_TOOLS_ROOT = Join-Path $devecoRoot "tools"
$env:TABSSH_HWSDK_ROOT = $hwsdkDir

$logRoot = Join-Path $tempRoot "tabssh_harmonyos_logs"
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$logPath = Join-Path $logRoot ("build_mock_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

Push-Location $StageRoot
try {
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  & $nodeExe $runner assembleHap *> $logPath
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorActionPreference
} finally {
  $ErrorActionPreference = "Stop"
  Pop-Location
}
if ($exitCode -ne 0) {
  Get-Content -LiteralPath $logPath -Tail 120
  throw "Hvigor build failed with exit code $exitCode. Log: $logPath"
}

if (Test-Path -LiteralPath $OutputRoot) {
  if (Get-ChildItem -LiteralPath $OutputRoot -Filter *.apk -File -Recurse -ErrorAction SilentlyContinue) {
    throw "Refusing to replace an output directory that contains APK files: $OutputRoot"
  }
  Remove-Item -LiteralPath $OutputRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$artifacts = Get-ChildItem -LiteralPath $StageRoot -File -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -in @(".hap", ".app") -and $_.FullName -match "\\outputs\\" }
if (-not $artifacts) {
  throw "Build succeeded but no HAP/APP was found under the staged outputs."
}
foreach ($artifact in $artifacts) {
  $destination = Join-Path $OutputRoot $artifact.Name
  Copy-Item -LiteralPath $artifact.FullName -Destination $destination -Force
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
  Write-Host ("Artifact: {0} ({1} bytes, SHA256 {2})" -f $destination, (Get-Item $destination).Length, $hash)
}

Write-Host "Build log: $logPath"
