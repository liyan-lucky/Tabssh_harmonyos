param(
  [string]$DependenciesRoot = "",
  [string]$NativeSdkRoot = "",
  [int]$Jobs = 8,
  [switch]$Rebuild
)

$ErrorActionPreference = "Stop"

$libssh2Version = "1.11.1"
$libssh2Tag = "libssh2-1.11.1"
$libssh2Commit = "a312b43325e3383c865a87bb1d26cb52e3292641"
$opensslVersion = "3.5.7"
$opensslTag = "openssl-3.5.7"
$opensslCommit = "8cf17aaeb4599f8af87fefd810b5b5fee90fe69e"
$zlibVersion = "1.3.2"
$zlibArchiveSha256 = "BB329A0A2CD0274D05519D61C667C062E06990D72E125EE2DFA8DE64F0119D16"

$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot ".."))
$tempRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot "99_Temp"))
if ([string]::IsNullOrWhiteSpace($DependenciesRoot)) {
  $DependenciesRoot = Join-Path $tempRoot "tabssh_harmonyos_dependencies"
}
$DependenciesRoot = [IO.Path]::GetFullPath($DependenciesRoot)
if (-not $DependenciesRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "DependenciesRoot must stay under $tempRoot"
}

if ([string]::IsNullOrWhiteSpace($NativeSdkRoot)) {
  if ($env:HARMONYOS_NATIVE_SDK) {
    $NativeSdkRoot = $env:HARMONYOS_NATIVE_SDK
  } else {
    $NativeSdkRoot = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\native"
  }
}
$NativeSdkRoot = [IO.Path]::GetFullPath($NativeSdkRoot)
$toolchain = Join-Path $NativeSdkRoot "build\cmake\ohos.toolchain.cmake"
$cmake = Join-Path $NativeSdkRoot "build-tools\cmake\bin\cmake.exe"
$ninja = Join-Path $NativeSdkRoot "build-tools\cmake\bin\ninja.exe"
$llvmBin = Join-Path $NativeSdkRoot "llvm\bin"
$msysPerl = "C:\msys64\usr\bin\perl.exe"
$msysMake = "C:\msys64\usr\bin\make.exe"
foreach ($requiredTool in @($toolchain, $cmake, $ninja, $llvmBin, $msysPerl, $msysMake)) {
  if (-not (Test-Path -LiteralPath $requiredTool)) {
    throw "Required native dependency build tool is missing: $requiredTool"
  }
}
if ($Jobs -lt 1) { throw "Jobs must be at least 1" }

$downloadRoot = Join-Path $DependenciesRoot "downloads"
$sourceRoot = Join-Path $DependenciesRoot "sources"
$buildRoot = Join-Path $DependenciesRoot "build"
$installRoot = Join-Path $DependenciesRoot "install"
$logRoot = Join-Path $tempRoot "tabssh_harmonyos_logs\native_dependencies"
foreach ($path in @($downloadRoot, $sourceRoot, $buildRoot, $installRoot, $logRoot)) {
  New-Item -ItemType Directory -Path $path -Force | Out-Null
}

function Remove-OwnedBuildPath([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $full = [IO.Path]::GetFullPath($Path)
  if (-not $full.StartsWith($DependenciesRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove a path outside DependenciesRoot: $full"
  }
  if (Get-ChildItem -LiteralPath $full -Filter *.apk -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) {
    throw "Refusing to remove a path containing APK files: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
}

function Invoke-Logged(
  [string]$Name,
  [string]$FilePath,
  [string[]]$Arguments,
  [string]$WorkingDirectory
) {
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $safeName = $Name -replace "[^A-Za-z0-9_.-]", "_"
  $logPath = Join-Path $logRoot ("{0}_{1}.log" -f $safeName, $stamp)
  Push-Location $WorkingDirectory
  try {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $FilePath @Arguments *> $logPath
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
  } finally {
    $ErrorActionPreference = "Stop"
    Pop-Location
  }
  if ($exitCode -ne 0) {
    Get-Content -LiteralPath $logPath -Tail 120
    throw "$Name failed with exit code $exitCode. Log: $logPath"
  }
  Write-Host "$Name log: $logPath"
  return $logPath
}

function Convert-ToMsysPath([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  if ($full -notmatch "^([A-Za-z]):\\(.*)$") {
    throw "Only absolute Windows drive paths can be converted for MSYS2: $full"
  }
  return "/$($Matches[1].ToLowerInvariant())/$($Matches[2].Replace('\', '/'))"
}

function Resolve-OpenSslLibrary([string]$InstallRoot, [string]$FileName) {
  foreach ($directory in @("lib", "lib64")) {
    $candidate = Join-Path $InstallRoot "$directory\$FileName"
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  return (Join-Path $InstallRoot "lib\$FileName")
}

function Ensure-GitSource(
  [string]$Name,
  [string]$Url,
  [string]$Tag,
  [string]$ExpectedCommit,
  [string]$Destination
) {
  if (-not (Test-Path -LiteralPath $Destination)) {
    Invoke-Logged "$Name-clone" "git.exe" @("clone", "--depth", "1", "--branch", $Tag, $Url, $Destination) $sourceRoot | Out-Null
  }
  $safe = $Destination.Replace("\", "/")
  $headLog = Invoke-Logged "$Name-head" "git.exe" @("-c", "safe.directory=$safe", "-C", $Destination, "rev-parse", "HEAD") $sourceRoot
  $head = (Get-Content -LiteralPath $headLog -Raw).Trim()
  if ($head -ne $ExpectedCommit) {
    throw "$Name source commit mismatch: expected $ExpectedCommit, got $head"
  }
}

$libssh2Source = Join-Path $sourceRoot "libssh2-$libssh2Version"
$opensslSource = Join-Path $sourceRoot "openssl-$opensslVersion"
$zlibArchive = Join-Path $downloadRoot "zlib-$zlibVersion.tar.gz"
$zlibSource = Join-Path $sourceRoot "zlib-$zlibVersion"

Ensure-GitSource "libssh2" "https://github.com/libssh2/libssh2.git" $libssh2Tag $libssh2Commit $libssh2Source
Ensure-GitSource "openssl" "https://github.com/openssl/openssl.git" $opensslTag $opensslCommit $opensslSource

if (-not (Test-Path -LiteralPath $zlibArchive)) {
  Invoke-WebRequest -Uri "https://github.com/madler/zlib/releases/download/v$zlibVersion/zlib-$zlibVersion.tar.gz" -OutFile $zlibArchive
}
$actualZlibHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zlibArchive).Hash
if ($actualZlibHash -ne $zlibArchiveSha256) {
  throw "zlib archive SHA256 mismatch: expected $zlibArchiveSha256, got $actualZlibHash"
}
if (-not (Test-Path -LiteralPath $zlibSource)) {
  Invoke-Logged "zlib-extract" "C:\Windows\System32\tar.exe" @("-xzf", $zlibArchive, "-C", $sourceRoot) $sourceRoot | Out-Null
}

$originalPath = $env:PATH
try {
  $env:PATH = "$llvmBin;C:\msys64\usr\bin;$originalPath"
  foreach ($abi in @("arm64-v8a", "x86_64")) {
    $triple = if ($abi -eq "arm64-v8a") { "aarch64-linux-ohos" } else { "x86_64-linux-ohos" }
    $opensslTarget = if ($abi -eq "arm64-v8a") { "linux-aarch64" } else { "linux-x86_64" }
    $abiBuildRoot = Join-Path $buildRoot $abi
    $abiInstallRoot = Join-Path $installRoot $abi
    $zlibBuild = Join-Path $abiBuildRoot "zlib"
    $zlibInstall = Join-Path $abiInstallRoot "zlib"
    $opensslBuild = Join-Path $abiBuildRoot "openssl-src"
    $opensslInstall = Join-Path $abiInstallRoot "openssl"
    $libssh2Build = Join-Path $abiBuildRoot "libssh2"
    $libssh2Install = Join-Path $abiInstallRoot "libssh2"

    if ($Rebuild) {
      foreach ($owned in @($zlibBuild, $zlibInstall, $opensslBuild, $opensslInstall, $libssh2Build, $libssh2Install)) {
        Remove-OwnedBuildPath $owned
      }
    }
    New-Item -ItemType Directory -Path $abiBuildRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $abiInstallRoot -Force | Out-Null

    $zlibLibrary = Join-Path $zlibInstall "lib\libz.a"
    if (-not (Test-Path -LiteralPath $zlibLibrary)) {
      Invoke-Logged "zlib-$abi-configure" $cmake @(
        "-S", $zlibSource, "-B", $zlibBuild, "-G", "Ninja",
        "-DCMAKE_MAKE_PROGRAM=$ninja", "-DCMAKE_TOOLCHAIN_FILE=$toolchain",
        "-DOHOS_ARCH=$abi", "-DOHOS_PLATFORM=OHOS", "-DCMAKE_BUILD_TYPE=Release",
        "-DBUILD_SHARED_LIBS=OFF", "-DZLIB_BUILD_EXAMPLES=OFF", "-DCMAKE_INSTALL_PREFIX=$zlibInstall"
      ) $projectRoot | Out-Null
      Invoke-Logged "zlib-$abi-build" $cmake @("--build", $zlibBuild, "--parallel", $Jobs.ToString()) $projectRoot | Out-Null
      Invoke-Logged "zlib-$abi-install" $cmake @("--install", $zlibBuild) $projectRoot | Out-Null
    }
    if (-not (Test-Path -LiteralPath $zlibLibrary)) { throw "zlib library missing after build: $zlibLibrary" }

    $opensslCrypto = Resolve-OpenSslLibrary $opensslInstall "libcrypto.a"
    $opensslSsl = Resolve-OpenSslLibrary $opensslInstall "libssl.a"
    if (-not (Test-Path -LiteralPath $opensslCrypto) -or -not (Test-Path -LiteralPath $opensslSsl)) {
      if (-not (Test-Path -LiteralPath $opensslBuild)) {
        New-Item -ItemType Directory -Path $opensslBuild -Force | Out-Null
        $copyArgs = @($opensslSource, $opensslBuild, "/E", "/COPY:DAT", "/DCOPY:DA", "/R:2", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/XD", (Join-Path $opensslSource ".git"))
        & robocopy @copyArgs | Out-Null
        if ($LASTEXITCODE -gt 7) { throw "OpenSSL source staging failed with robocopy exit code $LASTEXITCODE" }
      }
      if (-not (Test-Path -LiteralPath (Join-Path $opensslBuild "Makefile"))) {
        $env:CC = "clang --target=$triple"
        $env:CXX = "clang++ --target=$triple"
        $env:AR = "llvm-ar"
        $env:RANLIB = "llvm-ranlib"
        $env:STRIP = "llvm-strip"
        $msysPrefix = Convert-ToMsysPath $opensslInstall
        Invoke-Logged "openssl-$abi-configure" $msysPerl @(
          ".\Configure", $opensslTarget, "no-shared", "no-tests", "no-ui-console", "no-module",
          "no-legacy", "no-async", "no-asm", "--prefix=$msysPrefix", "--openssldir=$msysPrefix"
        ) $opensslBuild | Out-Null
      }
      Invoke-Logged "openssl-$abi-build" $msysMake @("-j", $Jobs.ToString(), "build_libs") $opensslBuild | Out-Null
      Invoke-Logged "openssl-$abi-install" $msysMake @("install_dev") $opensslBuild | Out-Null
      $opensslCrypto = Resolve-OpenSslLibrary $opensslInstall "libcrypto.a"
      $opensslSsl = Resolve-OpenSslLibrary $opensslInstall "libssl.a"
    }
    if (-not (Test-Path -LiteralPath $opensslCrypto) -or -not (Test-Path -LiteralPath $opensslSsl)) {
      throw "OpenSSL libraries missing after build for $abi"
    }

    $libssh2Library = Join-Path $libssh2Install "lib\libssh2.a"
    if (-not (Test-Path -LiteralPath $libssh2Library)) {
      Invoke-Logged "libssh2-$abi-configure" $cmake @(
        "-S", $libssh2Source, "-B", $libssh2Build, "-G", "Ninja",
        "-DCMAKE_MAKE_PROGRAM=$ninja", "-DCMAKE_TOOLCHAIN_FILE=$toolchain",
        "-DOHOS_ARCH=$abi", "-DOHOS_PLATFORM=OHOS", "-DCMAKE_BUILD_TYPE=Release",
        "-DBUILD_STATIC_LIBS=ON", "-DBUILD_SHARED_LIBS=OFF", "-DBUILD_EXAMPLES=OFF", "-DBUILD_TESTING=OFF",
        "-DCRYPTO_BACKEND=OpenSSL", "-DOPENSSL_USE_STATIC_LIBS=TRUE",
        "-DOPENSSL_INCLUDE_DIR=$opensslInstall\include", "-DOPENSSL_CRYPTO_LIBRARY=$opensslCrypto",
        "-DOPENSSL_SSL_LIBRARY=$opensslSsl", "-DZLIB_INCLUDE_DIR=$zlibInstall\include",
        "-DZLIB_LIBRARY=$zlibLibrary", "-DCMAKE_INSTALL_PREFIX=$libssh2Install"
      ) $projectRoot | Out-Null
      Invoke-Logged "libssh2-$abi-build" $cmake @("--build", $libssh2Build, "--parallel", $Jobs.ToString()) $projectRoot | Out-Null
      Invoke-Logged "libssh2-$abi-install" $cmake @("--install", $libssh2Build) $projectRoot | Out-Null
    }
    if (-not (Test-Path -LiteralPath $libssh2Library)) { throw "libssh2 library missing after build: $libssh2Library" }
  }
} finally {
  $env:PATH = $originalPath
  Remove-Item Env:CC,Env:CXX,Env:AR,Env:RANLIB,Env:STRIP -ErrorAction SilentlyContinue
}

$artifacts = @()
foreach ($abi in @("arm64-v8a", "x86_64")) {
  foreach ($entry in @(
    @{ Name = "zlib"; Path = Join-Path $installRoot "$abi\zlib\lib\libz.a" },
    @{ Name = "crypto"; Path = Resolve-OpenSslLibrary (Join-Path $installRoot "$abi\openssl") "libcrypto.a" },
    @{ Name = "ssl"; Path = Resolve-OpenSslLibrary (Join-Path $installRoot "$abi\openssl") "libssl.a" },
    @{ Name = "ssh2"; Path = Join-Path $installRoot "$abi\libssh2\lib\libssh2.a" }
  )) {
    $item = Get-Item -LiteralPath $entry.Path
    $artifacts += [ordered]@{
      abi = $abi
      library = $entry.Name
      path = $item.FullName
      size = $item.Length
      sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.FullName).Hash
    }
  }
}
$manifest = [ordered]@{
  generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
  nativeSdk = $NativeSdkRoot
  versions = [ordered]@{
    libssh2 = [ordered]@{ version = $libssh2Version; commit = $libssh2Commit }
    openssl = [ordered]@{ version = $opensslVersion; commit = $opensslCommit }
    zlib = [ordered]@{ version = $zlibVersion; archiveSha256 = $zlibArchiveSha256 }
  }
  artifacts = $artifacts
}
$manifestPath = Join-Path $DependenciesRoot "manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Host "Native dependency manifest: $manifestPath"
$artifacts | ForEach-Object { Write-Host ("{0} {1}: {2} bytes, SHA256 {3}" -f $_.abi, $_.library, $_.size, $_.sha256) }
