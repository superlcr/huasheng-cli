# hs —— 花生命令行

把[花生](https://www.huasheng.cn)做成命令行:**从一句话或一份文稿,到一条可导出、可投稿的成片**,
中途还能改到满意。为**外部开发者**和 **AI 客户端**准备 —— 每个命令都支持 `--json`。

单文件二进制,下载即用,**不需要装任何运行时**。

## 安装

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.sh | sh
```

**Windows**(PowerShell)

```powershell
irm https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.ps1 | iex
```

装完新开一个终端,然后:

```bash
hs auth login          # 浏览器授权登录
hs make --script "帮我做一条介绍杭州的短视频" --export ./out.mp4
```

`hs --help` 看全部命令,`hs help json` 是写脚本/接 AI 前必读的一篇。

## 不想跑 `curl | sh`?手动下载

从 [Releases](https://github.com/superlcr/huasheng-cli/releases/latest) 取对应平台的包,
解压后把 `hs` 放进 `PATH` 里的任意目录:

| 平台 | 文件 |
|---|---|
| macOS Apple Silicon | `hs-darwin-arm64.tar.gz` |
| macOS Intel | `hs-darwin-x64.tar.gz` |
| Linux x64 | `hs-linux-x64.tar.gz` |
| Windows x64 | `hs-windows-x64.zip` |

**请核对校验和** —— 每个 release 都附一份 `SHA256SUMS`:

```bash
shasum -a 256 -c SHA256SUMS
```

两个 macOS 包都经过 **Apple 签名与公证**(Developer ID Application)。用 `curl` 装的文件不带
quarantine 标记,Gatekeeper 不会检查;从浏览器下载的那份则会走在线校验,**首次运行需要联网**。

## 升级

```bash
hs upgrade
```

就是重跑一次上面的安装脚本。**不做**自动更新检查,也不做后台静默更新。

## 关于源码

本仓库只分发**构建产物与安装脚本**,不公开源码。原因很实在:`hs` 调的是花生尚未对外承诺的
内部接口,公开它的调用契约等于官方背书了一套随时可能变的东西 —— 后端改一行,就会变成
一次兼容性事故。等对外 open-api 稳定后会重新考虑。

保留所有权利。

## 反馈

用起来有问题、或者某个命令的行为不符合预期,欢迎开
[issue](https://github.com/superlcr/huasheng-cli/issues) —— 请附上 `hs --version` 的输出
(它带 commit 和构建时间,是定位问题的唯一线索)。
