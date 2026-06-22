param(
  [string]$HapPath = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = Join-Path $workspaceRoot "99_Temp"
if ([string]::IsNullOrWhiteSpace($HapPath)) {
  $HapPath = Join-Path $tempRoot "harmonyos_build\10_Tabssh_harmonyos\entry-default-unsigned.hap"
}
$HapPath = [IO.Path]::GetFullPath($HapPath)
if (-not (Test-Path -LiteralPath $HapPath)) { throw "HAP not found: $HapPath" }

$expected = @(
  "libs/arm64-v8a/libentry.so",
  "libs/arm64-v8a/libc++_shared.so",
  "libs/x86_64/libentry.so",
  "libs/x86_64/libc++_shared.so"
)
$archive = [IO.Compression.ZipFile]::OpenRead($HapPath)
try {
  foreach ($name in $expected) {
    $entry = $archive.GetEntry($name)
    if ($null -eq $entry -or $entry.Length -le 4) { throw "Missing or empty native entry: $name" }
    $stream = $entry.Open()
    try {
      $magic = New-Object byte[] 4
      if ($stream.Read($magic, 0, 4) -ne 4 -or $magic[0] -ne 0x7F -or $magic[1] -ne 0x45 -or $magic[2] -ne 0x4C -or $magic[3] -ne 0x46) {
        throw "Native entry is not ELF: $name"
      }
    } finally {
      $stream.Dispose()
    }
    Write-Host ("Verified {0} ({1} bytes)" -f $name, $entry.Length)
  }
} finally {
  $archive.Dispose()
}

$item = Get-Item -LiteralPath $HapPath
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $HapPath).Hash
Write-Host ("HAP: {0}" -f $HapPath)
Write-Host ("Size: {0}" -f $item.Length)
Write-Host ("SHA256: {0}" -f $hash)
Write-Host "This verifier checks package structure only; an unsigned HAP is not installation or release evidence."
