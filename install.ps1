# hs 安装器(Windows)。用法:
#   irm https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.ps1 | iex
#
# 覆盖点(与 install.sh 同名同义):HS_BASE_URL / HS_INSTALL_DIR
$ErrorActionPreference = "Stop"
# ★ review Important #5:Windows PowerShell 5.1(默认引擎,irm | iex 的绝大多数用户)
#   下,Invoke-WebRequest 默认每个数据块都重绘一次进度条,实测比关掉慢一个数量级——
#   37MB 的包会让人对着一个不动的进度条等上几分钟,像卡死。rustup/deno/bun 的官方
#   安装器都这么关。
$ProgressPreference = "SilentlyContinue"

$Repo    = if ($env:HS_REPO) { $env:HS_REPO } else { "superlcr/huasheng-cli" }
$BaseUrl = if ($env:HS_BASE_URL) { $env:HS_BASE_URL } else { "https://github.com/$Repo/releases/latest/download" }
$Dir     = if ($env:HS_INSTALL_DIR) { $env:HS_INSTALL_DIR } else { "$env:LOCALAPPDATA\Programs\hs" }

if ([System.Environment]::Is64BitOperatingSystem -eq $false) {
  throw "hs 目前只有 64 位版本"
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
  Write-Host "检测到 ARM64 设备,将安装 x64 版本,通过 Windows 的 x64 模拟层运行。"
}

$Asset = "hs-windows-x64.zip"
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null

try {
  Write-Host "下载 $Asset ..."
  Invoke-WebRequest -Uri "$BaseUrl/$Asset"     -OutFile "$Tmp\$Asset"      -UseBasicParsing
  Invoke-WebRequest -Uri "$BaseUrl/SHA256SUMS" -OutFile "$Tmp\SHA256SUMS"  -UseBasicParsing
  Write-Host "下载完成,校验中 ..."

  # 校验失败必须中止 —— 与 install.sh 同一条纪律
  $actual   = (Get-FileHash "$Tmp\$Asset" -Algorithm SHA256).Hash.ToLower()
  $line     = Select-String -Path "$Tmp\SHA256SUMS" -Pattern "\s$([regex]::Escape($Asset))$"
  if (-not $line) { throw "校验和清单里没有 $Asset" }
  $expected = ($line.Line -split '\s+')[0].ToLower()
  if ($actual -ne $expected) {
    throw "校验不通过 —— 下载到的内容和官方发布的不一致。`n  期望 $expected`n  实际 $actual`n这通常是下载没完整拿到,或者这个下载源不是官方的。已中止,什么都没有安装。"
  }

  New-Item -ItemType Directory -Path $Dir -Force | Out-Null
  Expand-Archive -Path "$Tmp\$Asset" -DestinationPath $Dir -Force
  Write-Host "✅ 装好了: $Dir\hs.exe"
  & "$Dir\hs.exe" --version

  # 只动用户级 PATH,不碰系统级 —— 不需要管理员权限
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*$Dir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$Dir", "User")
    Write-Host ""
    Write-Host "⚠ 已把 $Dir 加进 PATH,新开一个终端窗口才生效。"
  }
  Write-Host ""
  Write-Host "下一步:  hs auth login"
}
finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
