param(
  [string]$StageRoot = "",
  [string]$OutputRoot = "",
  [string]$DependenciesRoot = ""
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
if ([string]::IsNullOrWhiteSpace($DependenciesRoot)) {
  $DependenciesRoot = Join-Path $tempRoot "tabssh_harmonyos_dependencies"
}
$StageRoot = [IO.Path]::GetFullPath($StageRoot)
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
$DependenciesRoot = [IO.Path]::GetFullPath($DependenciesRoot)
foreach ($path in @($StageRoot, $OutputRoot, $DependenciesRoot)) {
  if (-not $path.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Real build paths must stay under $tempRoot"
  }
}

& (Join-Path $PSScriptRoot "update_build_info.ps1") | Out-Host
$manifestPath = Join-Path $DependenciesRoot "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "Native dependency manifest is missing. Run scripts\build_native_dependencies.ps1 first: $manifestPath"
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
foreach ($abi in @("arm64-v8a", "x86_64")) {
  foreach ($library in @("zlib", "crypto", "ssl", "ssh2")) {
    $entry = @($manifest.artifacts | Where-Object { $_.abi -eq $abi -and $_.library -eq $library })
    if ($entry.Count -ne 1) { throw "Dependency manifest entry missing or duplicated: $abi/$library" }
    $artifactPath = [IO.Path]::GetFullPath([string]$entry[0].path)
    if (-not $artifactPath.StartsWith($DependenciesRoot, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Dependency artifact escapes DependenciesRoot: $artifactPath"
    }
    if (-not (Test-Path -LiteralPath $artifactPath)) { throw "Dependency artifact is missing: $artifactPath" }
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash
    if ($actualHash -ne [string]$entry[0].sha256) {
      throw "Dependency artifact hash mismatch: $artifactPath"
    }
  }
}

& (Join-Path $PSScriptRoot "stage_project_for_build.ps1") -StageRoot $StageRoot | Out-Host
$thirdParty = Join-Path $StageRoot "entry\src\main\cpp\third_party"
New-Item -ItemType Directory -Path $thirdParty -Force | Out-Null

function Copy-Directory([string]$Source, [string]$Destination) {
  if (-not (Test-Path -LiteralPath $Source)) { throw "Dependency include directory is missing: $Source" }
  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  & robocopy $Source $Destination /E /COPY:DAT /DCOPY:DA /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -gt 7) { throw "robocopy failed for $Source with exit code $LASTEXITCODE" }
}

Copy-Directory (Join-Path $DependenciesRoot "install\arm64-v8a\libssh2\include") (Join-Path $thirdParty "libssh2\include")
Copy-Directory (Join-Path $DependenciesRoot "install\arm64-v8a\zlib\include") (Join-Path $thirdParty "zlib\include")
foreach ($abi in @("arm64-v8a", "x86_64")) {
  Copy-Directory (Join-Path $DependenciesRoot "install\$abi\openssl\include") (Join-Path $thirdParty "openssl\include\$abi")
  $abiLibraryRoot = Join-Path $thirdParty "libs\$abi"
  New-Item -ItemType Directory -Path $abiLibraryRoot -Force | Out-Null
  $mapping = @{
    "zlib" = "libz.a"
    "crypto" = "libcrypto.a"
    "ssl" = "libssl.a"
    "ssh2" = "libssh2.a"
  }
  foreach ($library in $mapping.Keys) {
    $entry = @($manifest.artifacts | Where-Object { $_.abi -eq $abi -and $_.library -eq $library })[0]
    Copy-Item -LiteralPath ([string]$entry.path) -Destination (Join-Path $abiLibraryRoot $mapping[$library]) -Force
  }
}
Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $thirdParty "manifest.json") -Force

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
$javaHome = if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
  $env:JAVA_HOME
} else {
  Join-Path $devecoRoot "jbr"
}
if (-not (Test-Path -LiteralPath (Join-Path $javaHome "bin\java.exe"))) {
  throw "Java runtime was not found: $javaHome"
}
$env:JAVA_HOME = $javaHome
$env:PATH = (Join-Path $javaHome "bin") + [IO.Path]::PathSeparator + $env:PATH
$env:DEVECO_TOOLS_ROOT = Join-Path $devecoRoot "tools"
$env:DEVECO_SDK_HOME = $hwsdkDir
$env:TABSSH_HWSDK_ROOT = $hwsdkDir
$logRoot = Join-Path $tempRoot "tabssh_harmonyos_logs"
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$logPath = Join-Path $logRoot ("build_real_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

Push-Location $StageRoot
try {
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  & $nodeExe $runner assembleHap *> $logPath
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousPreference
} finally {
  $ErrorActionPreference = "Stop"
  Pop-Location
}
if ($exitCode -ne 0) {
  Get-Content -LiteralPath $logPath -Tail 160
  throw "Real SSH Hvigor build failed with exit code $exitCode. Log: $logPath"
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
$artifacts = Get-ChildItem -LiteralPath $StageRoot -File -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -in @(".hap", ".app") -and $_.FullName -match "\\outputs\\" }
if (-not $artifacts) { throw "Build succeeded but no HAP/APP was found under the staged outputs." }
foreach ($artifact in $artifacts) {
  $baseName = [IO.Path]::GetFileNameWithoutExtension($artifact.Name)
  $destination = Join-Path $OutputRoot ("{0}-real{1}" -f $baseName, $artifact.Extension)
  Copy-Item -LiteralPath $artifact.FullName -Destination $destination -Force
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
  Write-Host ("Real artifact: {0} ({1} bytes, SHA256 {2})" -f $destination, (Get-Item $destination).Length, $hash)
}
Write-Host "Real build log: $logPath"
