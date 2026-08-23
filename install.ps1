# The hs installer for Windows. Usage:
#   irm https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.ps1 | iex
#
# Overrides (same names and meanings as install.sh): HS_BASE_URL / HS_INSTALL_DIR
$ErrorActionPreference = "Stop"
# On Windows PowerShell 5.1 — the default engine, and what almost everyone piping
# `irm | iex` is running — Invoke-WebRequest redraws its progress bar for every chunk
# of data, which measures an order of magnitude slower than turning it off. A 37 MB
# download would leave you staring at a frozen-looking bar for minutes. The official
# rustup, deno and bun installers all disable it for the same reason.
$ProgressPreference = "SilentlyContinue"

$Repo    = if ($env:HS_REPO) { $env:HS_REPO } else { "superlcr/huasheng-cli" }
$BaseUrl = if ($env:HS_BASE_URL) { $env:HS_BASE_URL } else { "https://github.com/$Repo/releases/latest/download" }
$Dir     = if ($env:HS_INSTALL_DIR) { $env:HS_INSTALL_DIR } else { "$env:LOCALAPPDATA\Programs\hs" }

if ([System.Environment]::Is64BitOperatingSystem -eq $false) {
  throw "hs is only available as a 64-bit build"
}

# There is no native ARM64 build of hs, but Windows 11 on ARM runs x64 programs through
# its built-in emulation layer — so do not refuse the install, just say what is happening.
# PROCESSOR_ARCHITECTURE reads as x86 inside a 32-bit host process; the real architecture
# is in PROCESSOR_ARCHITEW6432, which only exists for a 32-bit process on a 64-bit system.
$Arch = $env:PROCESSOR_ARCHITECTURE
if ($Arch -eq "x86" -and $env:PROCESSOR_ARCHITEW6432) {
  $Arch = $env:PROCESSOR_ARCHITEW6432
}
if ($Arch -eq "ARM64") {
  Write-Host "ARM64 detected. Installing the x64 build, which runs under Windows x64 emulation."
}

$Asset = "hs-windows-x64.zip"
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null

try {
  Write-Host "Downloading $Asset ..."
  Invoke-WebRequest -Uri "$BaseUrl/$Asset"     -OutFile "$Tmp\$Asset"      -UseBasicParsing
  Invoke-WebRequest -Uri "$BaseUrl/SHA256SUMS" -OutFile "$Tmp\SHA256SUMS"  -UseBasicParsing
  Write-Host "Downloaded. Verifying ..."

  # A failed checksum must stop the install — same rule as install.sh
  $actual   = (Get-FileHash "$Tmp\$Asset" -Algorithm SHA256).Hash.ToLower()
  $line     = Select-String -Path "$Tmp\SHA256SUMS" -Pattern "\s$([regex]::Escape($Asset))$"
  if (-not $line) { throw "$Asset is not listed in SHA256SUMS" }
  $expected = ($line.Line -split '\s+')[0].ToLower()
  if ($actual -ne $expected) {
    throw "Checksum mismatch: what was downloaded is not what was published.`n  expected $expected`n  actual   $actual`nUsually the download was incomplete, or this is not the official source.`nStopping. Nothing has been installed."
  }

  New-Item -ItemType Directory -Path $Dir -Force | Out-Null
  Expand-Archive -Path "$Tmp\$Asset" -DestinationPath $Dir -Force
  Write-Host "Installed: $Dir\hs.exe"
  & "$Dir\hs.exe" --version

  # Only the user-level PATH is touched, never the machine-level one, so no administrator
  # rights are needed.
  # A user-level Path may never have been set at all, in which case GetEnvironmentVariable
  # returns $null and "$userPath;$Dir" would write a Path whose first entry is empty. Mostly
  # harmless, but it is our own litter in someone's registry, and it only shows up on a brand
  # new account — exactly where nobody tests.
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ([string]::IsNullOrEmpty($userPath)) {
    [Environment]::SetEnvironmentVariable("Path", $Dir, "User")
    Write-Host ""
    Write-Host "Added $Dir to your PATH. Open a new terminal window for it to take effect."
  }
  elseif ($userPath -notlike "*$Dir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$Dir", "User")
    Write-Host ""
    Write-Host "Added $Dir to your PATH. Open a new terminal window for it to take effect."
  }
  Write-Host ""
  Write-Host "Next:  hs auth login"
}
finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
