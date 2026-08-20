# The hs installer for Windows. Usage:
#   irm https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.ps1 | iex
#
# Overrides (same names and meanings as install.sh): HS_BASE_URL / HS_INSTALL_DIR
$ErrorActionPreference = "Stop"
# ★ Windows PowerShell 5.1(默认引擎,irm | iex 的绝大多数用户)
#   下,Invoke-WebRequest 默认每个数据块都重绘一次进度条,实测比关掉慢一个数量级——
#   37MB 的包会让人对着一个不动的进度条等上几分钟,像卡死。rustup/deno/bun 的官方
#   安装器都这么关。
$ProgressPreference = "SilentlyContinue"

$Repo    = if ($env:HS_REPO) { $env:HS_REPO } else { "superlcr/huasheng-cli" }
$BaseUrl = if ($env:HS_BASE_URL) { $env:HS_BASE_URL } else { "https://github.com/$Repo/releases/latest/download" }
$Dir     = if ($env:HS_INSTALL_DIR) { $env:HS_INSTALL_DIR } else { "$env:LOCALAPPDATA\Programs\hs" }

if ([System.Environment]::Is64BitOperatingSystem -eq $false) {
  throw "hs is only available as a 64-bit build"
}

# ARM64 设备(如 Surface Pro X)没有专门的 hs 版本,但 Windows 11 on ARM
# 能通过内置的 x64 模拟层运行 x64 程序,所以不拒绝安装,只告知用户实情。
# PROCESSOR_ARCHITECTURE 在 32 位宿主进程下会读成 x86,真实架构要看
# PROCESSOR_ARCHITEW6432(64 位系统上,32 位进程才会有这个变量)。
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

  # 校验失败必须中止 —— 与 install.sh 同一条纪律
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

  # 只动用户级 PATH,不碰系统级 —— 不需要管理员权限
  # ★ 用户级 Path 可能**根本没设过**,那时 GetEnvironmentVariable 返回 $null ——
  #   直接 "$userPath;$Dir" 会写出一个以 `;` 开头的 Path(头一项是空串)。
  #   多数情况下无害,但它是我们亲手写进注册表的垃圾,而且只在全新账号上出现,
  #   平时测不到。
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
