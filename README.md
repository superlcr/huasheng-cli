<div align="center">

# hs · 花生命令行

**从一句话到一条可投稿的成片**

[![Release](https://img.shields.io/github/v/release/superlcr/huasheng-cli?style=flat-square&color=00a1d6)](https://github.com/superlcr/huasheng-cli/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square)](https://github.com/superlcr/huasheng-cli/releases/latest)

**简体中文** · [English](README.en.md)

</div>

---

`hs` 把[花生](https://www.huasheng.cn)的视频创作能力做成了命令行:给一句话或一份文稿,
它替你完成选题、分镜、配音、素材、合成,产出一条可以直接导出或投稿的视频。
中途每一步都能介入修改。

**单文件二进制,下载即用**,不需要 Node、Python 或任何运行时。
每条命令都支持 `--json`,为脚本与 AI 客户端设计。

## 先选一种用法

`hs` 只有一个安装包,但有两种运行方式:

```text
                         同一个 hs
                            │
              ┌─────────────┴─────────────┐
              │                           │
        你直接运行 hs 命令          AI 启动 hs mcp serve
              │                           │
           hs CLI                  hs MCP server
                                          │
                              ┌───────────┴───────────┐
                              │                       │
                         桌面 AI 客户端          终端 AI 客户端
                         有可视化交互卡           完整文字结果
```

`hs mcp serve` 不是另一套产品,也不用单独安装。它只是让 AI 客户端调用同一个 `hs`、
使用同一份登录态的一种启动方式。

| 你想怎么用 | 选这条路 | 你如何操作 |
| :--- | :--- | :--- |
| 和 AI 对话,还想直接看时间轴、预览和素材卡 | [桌面 AI 客户端](#桌面-ai-客户端) | 在 ChatGPT / Claude 里说人话、点卡片 |
| 在终端里和编码 Agent 对话 | [终端 AI 客户端](#终端-ai-客户端) | 在 Codex CLI / Claude Code 里说人话 |
| 自己敲命令,或写脚本、跑批量任务 | [直接使用 hs CLI](#直接使用-hs-cli) | 运行 `hs make`、`hs clip` 等命令 |

三条路的共同前置步骤只有一次:安装 `hs`,然后登录。

## 第一步:安装并登录

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
(Windows 为 `%LOCALAPPDATA%\Programs\hs`)。装完请新开一个终端。

### 手动下载

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

### 登录一次

安装完成后授权并验证 `hs` 本体:

```bash
hs auth login
hs account       # 能看到花生米余额就说明安装和登录都成功
```

所有使用方式共用 `~/.hs/credentials.json`。这里登录一次,CLI、ChatGPT、Claude、Codex
都不需要重复登录。

## 桌面 AI 客户端

这条路适合想在对话里完成创作、同时直接查看和操作可视化卡片的人。桌面客户端会在后台
启动 `hs mcp serve`;你不需要自己运行这条命令。

### ChatGPT Desktop App

ChatGPT 桌面客户端可以直接运行本机的 `hs` MCP server,并显示时间轴、逐条预览和
换画面的缩略图网格。

1. 打开 **Settings → MCP servers → Add server**
2. 名称填 `huasheng`,类型选 **STDIO**
3. Command 填 `hs` 的完整路径:macOS / Linux 在终端运行 `which hs`,Windows 运行 `where hs`
4. Arguments 依次填 `mcp`、`serve`,保存后点 **Restart**
5. 新开对话,输入 `/mcp`,确认 `huasheng` 已连接

> ChatGPT Desktop App 与 Codex CLI 共用 `~/.codex/config.toml`。在这里加过一次,
> Codex CLI 不用再配。详见 [OpenAI MCP 文档](https://developers.openai.com/codex/mcp)。

### Claude Desktop App

Claude Desktop 同样能显示花生的可视化交互卡。

1. 下载 **[huasheng.mcpb](https://github.com/superlcr/huasheng-cli/releases/latest/download/huasheng.mcpb)**
2. **双击**它,Claude Desktop 会弹出安装窗口,点「安装」
3. 它会问 `hs` 装在哪 —— 默认已经填好 `~/.local/bin/hs`,直接确认即可

> **为什么还要填一次路径**:Claude Desktop 不读终端的 PATH。
> 改过安装位置的话,终端里跑 `which hs`(Windows 用 `where hs`)看到的就是要填的。
> 首次安装会提示这个包未签名,选择继续即可。

### 桌面端怎么使用

新开一个对话,先问:

> 花生里我还有多少花生米?

看到余额后就可以直接说:

> 用花生做一条 30 秒的视频,讲讲为什么天是蓝的

项目、分镜、历史、设置、素材选择和导出会按场景显示为交互卡。确认分镜方案会扣花生米,
投稿会发到公网;客户端会在这两个动作前要求你确认。

## 终端 AI 客户端

这条路适合已经在终端使用编码 Agent 的人。AI 仍通过 `hs mcp serve` 调用花生,但终端不渲染
桌面交互卡,所以结果以完整文字和结构化数据呈现。

### Codex CLI

```bash
codex mcp add huasheng -- hs mcp serve
codex mcp list
```

如果已经在 ChatGPT Desktop App 里添加过 `huasheng`,这里无需重复添加;进入 Codex 后用
`/mcp` 查看连接状态。

### Claude Code CLI

```bash
claude mcp add --scope user huasheng -- hs mcp serve
claude mcp list
```

> Codex CLI 与 Claude Code CLI **不显示 Desktop 的可视化交互卡**,但会收到同一工具的
> 完整文字和结构化结果,所有主流程照样可用。

### 终端 Agent 怎么使用

进入 Codex 或 Claude Code 后直接说:

> 列出我最近的花生项目

> 把第 2 个分镜的口播改短一点

不要在终端里手工运行 `hs mcp serve`;上面的 `mcp add` 配置会在需要时自动启动它。

### 其它 MCP 客户端

任何支持 MCP 的客户端,手工加这一段:

```json
{"mcpServers": {"huasheng": {"command": "hs", "args": ["mcp", "serve"]}}}
```

## 直接使用 hs CLI

这条路不经过 AI 客户端。你自己运行 `hs` 命令,适合自动化、批量任务和需要精确控制每一步的场景。

一条命令完成创作并下载:

```bash
hs make --script "介绍杭州西湖的三个冷知识" --yes --out ./out.mp4
```

`--yes` 表示你同意确认方案时扣除花生米。想逐步查看、修改和确认,阅读
[hs CLI 使用指南](docs/cli.md);写脚本或批量任务则看[脚本与自动化](docs/automation.md)。

## 所有方式共用的创作流程

无论命令来自你还是 AI,底层都是同一个项目状态机:

```
create → PLANNING
       → PAUSED       agent 在等你回答问题
       → PLANNING
       → PLAN_READY   方案就绪,等你确认
       → PRODUCING    逐个分镜出视频
       → READY        成片可用
```

| 状态 | 含义 |
| :--- | :--- |
| `QUEUED` | 排队中(`hs fast` 可以插队) |
| `PLANNING` | agent 在思考或制作 |
| `PAUSED` | **在等你回答问题** |
| `PLAN_READY` | 方案就绪,等你确认(确认才扣米) |
| `PRODUCING` | 成片中 |
| `READY` | 可导出、可投稿 |
| `FAILED` | 失败,原因见 `hs project show` 的 `reason` |

AI 客户端会在需要你回答或确认时直接提问。CLI 用户如何推进这些状态,见
[hs CLI 使用指南](docs/cli.md)。

## 继续查阅

- [hs CLI 使用指南](docs/cli.md):分步创作、项目状态与完整命令表
- [脚本与自动化](docs/automation.md):`--json`、退出码、批处理与 ID
- [登录、隐私与系统要求](docs/security.md):凭据、联网范围和支持平台

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
