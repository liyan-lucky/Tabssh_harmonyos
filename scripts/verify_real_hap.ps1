param(
  [string]$HapPath = "",
  [string]$InspectRoot = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
if ([string]::IsNullOrWhiteSpace($HapPath)) {
  $HapPath = Join-Path $tempRoot "harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned-real.hap"
}
if ([string]::IsNullOrWhiteSpace($InspectRoot)) {
  $InspectRoot = Join-Path $tempRoot ("release_inspect\10_Tabssh_harmonyos\real_{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
}
$HapPath = [IO.Path]::GetFullPath($HapPath)
$InspectRoot = [IO.Path]::GetFullPath($InspectRoot)
if (-not $HapPath.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "HapPath must stay under $tempRoot"
}
if (-not $InspectRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "InspectRoot must stay under $tempRoot"
}
if (-not (Test-Path -LiteralPath $HapPath)) { throw "Real HAP not found: $HapPath" }
New-Item -ItemType Directory -Path $InspectRoot -Force | Out-Null

$llvmRoot = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\native\llvm\bin"
$readObject = Join-Path $llvmRoot "llvm-readobj.exe"
$strings = Join-Path $llvmRoot "llvm-strings.exe"
foreach ($tool in @($readObject, $strings)) {
  if (-not (Test-Path -LiteralPath $tool)) { throw "LLVM verifier tool is missing: $tool" }
}

$expected = @{
  "libs/arm64-v8a/libentry.so" = "EM_AARCH64"
  "libs/x86_64/libentry.so" = "EM_X86_64"
}
$archive = [IO.Compression.ZipFile]::OpenRead($HapPath)
try {
  foreach ($entryName in $expected.Keys) {
    $entry = $archive.GetEntry($entryName)
    if ($null -eq $entry -or $entry.Length -le 4) { throw "Missing or empty real native entry: $entryName" }
    $abi = ($entryName -split "/")[1]
    $destination = Join-Path $InspectRoot ("libentry_{0}.so" -f $abi)
    $input = $entry.Open()
    $output = [IO.File]::Open($destination, [IO.FileMode]::Create, [IO.FileAccess]::Write)
    try { $input.CopyTo($output) } finally { $output.Dispose(); $input.Dispose() }
    $headers = & $readObject --file-headers $destination 2>&1
    if ($LASTEXITCODE -ne 0 -or ($headers -join "`n") -notmatch [regex]::Escape($expected[$entryName])) {
      throw "Unexpected ELF machine for $entryName"
    }
    $text = (& $strings $destination 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "llvm-strings failed for $entryName" }
    if ($text -notmatch "real-ssh" -or $text -notmatch "libssh2") {
      throw "Real Core build marker is missing from $entryName"
    }
    if ($text -match "OpenTabSsh mock shell ready") {
      throw "Mock shell marker was found in a claimed real HAP: $entryName"
    }
    Write-Host ("Verified real {0} ({1} bytes, SHA256 {2})" -f $entryName, $entry.Length,
      (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash)
  }
} finally {
  $archive.Dispose()
}

$item = Get-Item -LiteralPath $HapPath
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $HapPath).Hash
Write-Host ("Real HAP: {0}" -f $HapPath)
Write-Host ("Size: {0}" -f $item.Length)
Write-Host ("SHA256: {0}" -f $hash)
Write-Host ("Inspection: {0}" -f $InspectRoot)
Write-Host "This verifier proves real-core packaging markers only; SSH/SFTP/forwarding still require end-to-end traffic evidence."
