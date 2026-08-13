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

## 安装

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

## 快速开始

```bash
hs auth login                    # 浏览器授权登录
hs account                       # 看一眼花生米余额
```

**一条命令做完整片:**

```bash
hs make --script "介绍杭州西湖的三个冷知识" --yes --out ./out.mp4
```

`hs make` 会一路跑到底 —— 自动回答 agent 的反问、确认方案、等待成片、下载到本地。
`--yes` 必须显式给出,因为确认方案会**扣除花生米且不可逆**;不给就停在报价那一步等你决定。

`--script` 也接受文件:`--script @script.txt`。

## 分步来:看清每一步

想在中途介入,就按项目的生命周期一步步走:

```bash
hs project create --script "…"   # 建项目,拿到 pid
hs use <pid>                     # 记住它,之后所有命令都不用再带 --pid

hs wait                          # 等到下一个需要你决策的时刻
hs chat answer "选第二个方案"      # 回答 agent 的反问
hs plan show --cost              # 查看分镜方案和价格
hs plan confirm --yes            # 确认开始成片(★ 扣花生米)

hs clip ls                       # 看所有分镜
hs clip edit --clip 3 --text "…" # 改第 3 个分镜的口播
hs settings                      # 列出全部呈现设置
hs settings subtitle-size 42     # 调字号;同理 aspect / voice / speed / bgm…

hs export get --out ./out.mp4    # 导出到本地
hs publish --submit --title "…"  # 投稿到 B 站
```

### 项目会经过哪些状态

```
create → PLANNING
       → PAUSED       agent 在等你回答问题        → hs chat answer
       → PLANNING
       → PLAN_READY   方案就绪,等你确认            → hs plan confirm --yes
       → PRODUCING    逐个分镜出视频
       → READY        成片可用                     → hs export / hs publish
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

`hs wait` 会一直等到 `PAUSED` / `PLAN_READY` / `READY` / `FAILED` 之一 ——
这四个是**唯一需要你做决定**的时刻,其余都只是等待。

每条命令的返回里都带 `next_actions`,直接告诉你下一步能做什么。

## 命令一览

| 命令 | 用途 |
| :--- | :--- |
| `hs auth` | 登录 / 查看状态 / 退出 |
| `hs account` | 花生米余额(余额为 0 时连改一个字都会被拒) |
| `hs make` | **一键成片**:一句话进去,成片出来 |
| `hs project` | 建项目 / 看状态 / 列表 / 删除 |
| `hs use` | 记住当前项目,之后省掉 `--pid` |
| `hs wait` | 等到下一个需要决策的时刻 |
| `hs plan` | 查看分镜方案 / 确认成片 |
| `hs chat` | 与 agent 对话:回答反问 / 提要求 / 看事件流 |
| `hs clip` | 分镜:改口播 / 增删 / 拆合 / 换素材 / 字幕 |
| `hs settings` | 项目呈现设置:画幅 / 音色 / 语速 / 字幕 / BGM |
| `hs voice` | 可用音色(建项目前挑选) |
| `hs pref` | 创作偏好(跟着**人**走,不属于任何项目) |
| `hs material` | 素材库:登记公网素材 / 管理文件夹 |
| `hs snapshot` | 存档点:回退 / 重做 / 跳到某条指令之前 |
| `hs export` | 导出成片到本地 |
| `hs publish` | 投稿到 B 站(**唯一会把内容发到公网的命令**) |
| `hs fast` | 快速通道:排队排不动时的出口 |
| `hs upgrade` | 升级到最新版 |

`hs --help` 看总览,`hs help <命令>` 看单条命令的完整参数。

## 给脚本与 AI 客户端

每条命令加 `--json` 即输出结构化对象,字段一律 `snake_case`。

**成功**时直接就是数据:

```console
$ hs project show --json
{"pid": 207385096749080, "state": "READY", ...}
```

**失败**时是统一的错误信封:

```json
{
  "error": {
    "code": "CONFIRM_REQUIRED",
    "message": "...",
    "retryable": false,
    "suggested_action": "confirm",
    "next_command": "hs plan confirm --pid ... --yes"
  }
}
```

- `suggested_action` ∈ `login` · `topup` · `retry` · `confirm` · `null`
- `next_command` 只在**确实有一条照抄就能跑的命令**时才出现

**退出码:** `0` 成功 · `1` 命令失败(错误在 stdout 的 `error` 里)· `2` 用法错误。

### 三条容易搞错的约定

> **`CONFIRM_REQUIRED` 的正确反应是回头问人**,不是自己加 `--yes` 重试。
> `next_command` 是给**人点头之后**照抄用的。
>
> **分镜写操作返回 `applied: false` 不是失败**,是还在后台执行。
>
> **`hs wait` 返回 `timed_out: true` 不是失败**,再调一次接着等。

完整约定见 `hs help json`。

### ⚠ 三种 id 不要混用

| id | 长度 | 说明 |
| :--- | :--- | :--- |
| `pid` | 15 位 | 绝大多数命令用它,`hs` 对外**只认 pid** |
| 内部 id | 7 位 | 部分接口内部需要,`hs` 自动换算,你不用管 |
| `clip_id` | 9 位 | 分镜级;`hs clip --clip` 同时接受序号和 `clip_id` |

**最容易踩的一个坑:`hs project ls --json` 里的 `id` 是内部 id,`pid` 才是 15 位那个。**
脚本里请一律取 `pid` 字段。详见 `hs help ids`。

## 升级

```bash
hs upgrade
```

即重新执行一次安装脚本。`hs` **不做**自动更新检查,也不做后台静默更新。

## 系统要求

- **macOS** 11 及以上(Apple Silicon 与 Intel 均有原生包)
- **Linux** glibc 2.31 及以上(Ubuntu 20.04+ / Debian 11+ / CentOS Stream 9+)
- **Windows** 10 及以上,x64;Windows on ARM 通过系统的 x64 模拟层运行

## 反馈

使用中遇到问题,欢迎提交 [issue](https://github.com/superlcr/huasheng-cli/issues)。
请附上 `hs --version` 的输出 —— 它包含 commit 与构建时间,是定位问题的关键线索。
