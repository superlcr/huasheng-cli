<div align="center">

# hs · 花生命令行

**从一句话到一条可投稿的成片**

[![Release](https://img.shields.io/github/v/release/superlcr/huasheng-cli?style=flat-square&color=00a1d6)](https://github.com/superlcr/huasheng-cli/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](https://github.com/superlcr/huasheng-cli/releases/latest)

**简体中文** · [English](README.md)

</div>

---

`hs` 把[花生](https://www.huasheng.cn)的视频创作能力做成了命令行:给一句话或一份文稿,
它替你完成选题、分镜、配音、素材、合成,产出一条可以直接导出或投稿的视频。
中途每一步都能介入修改。

**单文件二进制,下载即用**,不需要 Node、Python 或任何运行时。
每条命令都支持 `--json`,为脚本与 AI 客户端设计。

## 第一步:安装并登录

无论之后使用哪种客户端,这一步都只做一次。

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.sh | sh
```

### Windows

在 PowerShell 中执行:

```powershell
irm https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.ps1 | iex
```

安装脚本会下载对应平台的包、**校验 SHA256**、解压到 `~/.local/bin`
(Windows 为 `%LOCALAPPDATA%\Programs\hs`)。

### 用 npm

本来就在 Node 生态里,或者只想先试试、什么都不装:

```bash
npx @superlcr/hs --help
npm install -g @superlcr/hs    # 装完命令仍然叫 hs
```

npm 包里只有一个很小的启动器,对应平台的二进制作为可选依赖装进来 ——
安装时不下载、不编译。和上面 release 里的是同一个二进制。

安装完成后新开一个终端,登录并确认能读到花生米余额:

```bash
hs auth login
hs account
```

CLI 和所有 AI 客户端共用 `~/.hs/credentials.json`,不需要分别登录。

<details>
<summary>不使用安装脚本:手动下载</summary>

<br>

从 [Releases](https://github.com/superlcr/huasheng-cli/releases/latest) 下载对应平台的包,
解压后把可执行文件放进 `PATH` 中的任意目录:

| 平台 | 文件 |
| :--- | :--- |
| macOS · Apple Silicon | `hs-darwin-arm64.tar.gz` |
| macOS · Intel | `hs-darwin-x64.tar.gz` |
| Linux · x64 | `hs-linux-x64.tar.gz` |
| Windows · x64 | `hs-windows-x64.zip` |

每个 release 都附有 `SHA256SUMS`,**建议核对**:

```bash
shasum -a 256 -c SHA256SUMS
```

> 两个 macOS 包均经 Apple 签名与公证(Developer ID Application)。
> Windows 包未签名,首次运行可能出现 SmartScreen 提示,选择「更多信息 → 仍要运行」。

</details>

安装并登录后,有两种用法。两者使用同一个 `hs` 和同一份登录态。

## 用法一:直接使用 hs CLI

适合自己敲命令、写脚本或跑批量任务。`hs make` 可以从一句话或一份文稿开始,
自动完成创作、等待成片并下载。

用一句话生成视频:

```bash
hs make --script "介绍杭州西湖的三个冷知识" --yes --out ./out.mp4
```

指定 MG 风格:

```bash
hs make --script "用 30 秒解释宋代点茶" --mode mg --yes --out ./tea.mp4
```

从文件读取长文稿:

```bash
hs make --script @script.txt --yes --out ./video.mp4
```

`--yes` 表示你同意在方案确认时扣除花生米;不加时会停在报价确认处。
更多参数、分步修改、续跑和导出方法见[hs CLI 使用指南](docs/cli.zh.md),
JSON、退出码和批量任务见[脚本与自动化](docs/automation.zh.md)。

## 用法二:通过 MCP 在 AI 客户端中使用

`hs` 内置 MCP server。任何支持本地 STDIO MCP 的 AI 客户端,都可以通过下面的配置启动它:

```json
{
  "mcpServers": {
    "huasheng": {
      "command": "hs",
      "args": ["mcp", "serve"]
    }
  }
}
```

这段配置的含义只有一件事:需要使用花生时,客户端运行 `hs mcp serve`。
不需要单独安装 hs MCP,也不要自己常驻运行这条命令。如果客户端提示找不到 `hs`,
把 `command` 换成 `which hs`(Windows 用 `where hs`)输出的完整路径。

下面是四个常见客户端的具体配置方法。使用其他 MCP 客户端时,把上面的同一组
`command` 和 `args` 填入它的 MCP server 设置即可。

### ChatGPT Desktop App

1. 打开 **Settings → MCP servers → Add server**
2. 名称填 `huasheng`,类型选 **STDIO**
3. Command 填 `hs` 的完整路径,Arguments 依次填 `mcp`、`serve`
4. 保存并重启,然后输入 `/mcp` 确认 `huasheng` 已连接

ChatGPT Desktop 会显示时间轴、预览、素材选择和导出等交互卡片。它与 Codex CLI
共用 `~/.codex/config.toml`,所以在这里配置后 Codex CLI 也能直接使用。

### Claude Desktop App

1. 下载 **[huasheng.mcpb](https://github.com/superlcr/huasheng-cli/releases/latest/download/huasheng.mcpb)**
2. 双击打开,在 Claude Desktop 中点「安装」
3. 确认 `hs` 的路径;默认是 `~/.local/bin/hs`

如果改过安装位置,填入 `which hs`(Windows 用 `where hs`)输出的完整路径。
首次安装提示扩展未签名时,选择继续。Claude Desktop 同样会显示交互卡片。

### Codex CLI

```bash
codex mcp add huasheng -- hs mcp serve
codex mcp list
```

如果已经在 ChatGPT Desktop 中添加过 `huasheng`,无需重复执行。两者共享
`~/.codex/config.toml`。[OpenAI MCP 文档](https://developers.openai.com/codex/mcp)

### Claude Code CLI

```bash
claude mcp add --scope user huasheng -- hs mcp serve
claude mcp list
```

这两条都在你刚刚登录过的那个终端里跑,所以直接写 `hs` 就能找到;万一找不到,换成 `which hs`
(Windows 用 `where hs`)输出的完整路径。Codex CLI 与 Claude Code 使用完整文字结果,
不显示桌面客户端的交互卡片。

### 直接聊天使用

配置完成后,在 AI 客户端里直接说:

> 用花生做一条 30 秒的视频,讲讲为什么天是蓝的

也可以查看和继续修改已有项目:

> 列出我最近的花生项目

> 把第 2 个分镜的口播改短一点

> 给第 3 个分镜换一个更有科技感的画面

确认分镜方案会扣花生米,投稿会发布到公网;客户端会在执行前要求你确认。

## 更多文档

- [hs CLI 使用指南](docs/cli.zh.md):分步创作、项目状态与完整命令表
- [脚本与自动化](docs/automation.zh.md):`--json`、退出码、批处理与 ID
- [登录、隐私与系统要求](docs/security.zh.md):凭据、联网范围和支持平台

## 安全边界

- CLI 与所有 AI 客户端共用一份本机登录凭据;`hs` 不接触你的 B 站密码。
- 确认分镜方案会扣花生米,投稿会发到公网;这两个动作都必须由你确认。
- 文稿和素材会上传到花生用于生成视频;`hs` 没有独立遥测或后台自动更新。

## 升级

```bash
hs upgrade
```

即重新执行一次安装脚本。`hs` **不做**自动更新检查,也不做后台静默更新。

## 反馈

使用中遇到问题,欢迎提交 [issue](https://github.com/superlcr/huasheng-cli/issues)。
请附上 `hs --version` 的输出 —— 它包含 commit 与构建时间,是定位问题的关键线索。
