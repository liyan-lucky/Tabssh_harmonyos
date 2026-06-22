param(
  [int]$Port = 2222,
  [string]$TestRoot = ""
)

$ErrorActionPreference = "Stop"
if ($Port -lt 1024 -or $Port -gt 65535) { throw "Test SSH port must be between 1024 and 65535" }
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
if ([string]::IsNullOrWhiteSpace($TestRoot)) {
  $TestRoot = Join-Path $tempRoot "tabssh_harmonyos_dependencies\test_server"
}
$TestRoot = [IO.Path]::GetFullPath($TestRoot)
if (-not $TestRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "TestRoot must stay under $tempRoot"
}

$archive = Join-Path $TestRoot "downloads\OpenSSH-Win64.zip"
$runtime = Join-Path $TestRoot "runtime"
$privateRoot = Join-Path $TestRoot "private"
$logRoot = Join-Path $tempRoot "tabssh_harmonyos_logs\test_sshd"
foreach ($path in @($runtime, $privateRoot, $logRoot)) {
  New-Item -ItemType Directory -Path $path -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $archive)) {
  throw "Portable OpenSSH archive is missing: $archive"
}
$sshd = Join-Path $runtime "OpenSSH-Win64\sshd.exe"
if (-not (Test-Path -LiteralPath $sshd)) {
  Expand-Archive -LiteralPath $archive -DestinationPath $runtime -Force
}
if (-not (Test-Path -LiteralPath $sshd)) { throw "Portable sshd.exe was not extracted: $sshd" }

$hostKey = Join-Path $privateRoot "ssh_host_ed25519_key"
$clientKey = Join-Path $privateRoot "client_ed25519"
foreach ($key in @($hostKey, $clientKey)) {
  if (-not (Test-Path -LiteralPath $key)) {
    & (Join-Path (Split-Path -Parent $sshd) "ssh-keygen.exe") -q -t ed25519 -N '""' -f $key
    if ($LASTEXITCODE -ne 0) { throw "ssh-keygen failed for a private test key" }
  }
}
$authorizedKeys = Join-Path $privateRoot "authorized_keys"
Copy-Item -LiteralPath ($clientKey + ".pub") -Destination $authorizedKeys -Force

# The test keys remain local and are readable only by the current account and SYSTEM.
& icacls.exe $privateRoot /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" "SYSTEM:(OI)(CI)F" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to restrict test key directory ACL" }

function SshPath([string]$Path) { return $Path.Replace("\", "/") }
$config = Join-Path $privateRoot "sshd_config"
$pidFile = Join-Path $privateRoot "sshd.pid"
$lines = @(
  "Port $Port",
  "ListenAddress 127.0.0.1",
  "HostKey $(SshPath $hostKey)",
  "PidFile $(SshPath $pidFile)",
  "AuthorizedKeysFile $(SshPath $authorizedKeys)",
  "PubkeyAuthentication yes",
  "PasswordAuthentication no",
  "KbdInteractiveAuthentication no",
  "PermitEmptyPasswords no",
  "AuthenticationMethods publickey",
  "StrictModes no",
  "Subsystem sftp internal-sftp",
  "LogLevel ERROR"
)
Set-Content -LiteralPath $config -Value $lines -Encoding ASCII

if (Test-Path -LiteralPath $pidFile) {
  $oldPidText = (Get-Content -LiteralPath $pidFile -Raw).Trim()
  if ($oldPidText -match "^[0-9]+$") {
    $oldProcess = Get-Process -Id ([int]$oldPidText) -ErrorAction SilentlyContinue
    if ($null -ne $oldProcess -and $oldProcess.Path -eq $sshd) {
      Stop-Process -Id $oldProcess.Id -Force
    }
  }
}

& $sshd -t -f $config
if ($LASTEXITCODE -ne 0) { throw "Portable sshd configuration validation failed" }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stdoutLog = Join-Path $logRoot "sshd_${stamp}.out.log"
$stderrLog = Join-Path $logRoot "sshd_${stamp}.err.log"
$process = Start-Process -FilePath $sshd -ArgumentList @("-D", "-e", "-f", $config) -WindowStyle Hidden `
  -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru

$ready = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
  Start-Sleep -Milliseconds 200
  if ($process.HasExited) {
    Get-Content -LiteralPath $stderrLog -Tail 80 -ErrorAction SilentlyContinue
    throw "Portable sshd exited with code $($process.ExitCode)"
  }
  if (Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue) {
    $ready = $true
    break
  }
}
if (-not $ready) {
  Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
  throw "Portable sshd did not listen on 127.0.0.1:$Port"
}

Write-Host "Test sshd PID: $($process.Id)"
Write-Host "Test endpoint: 127.0.0.1:$Port"
Write-Host "Test username: $($env:USERNAME.ToLowerInvariant())"
Write-Host "Client key path: $clientKey"
Write-Host "Server stderr log: $stderrLog"
