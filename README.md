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

## 在 AI 客户端里用

装好 `hs` 之后,让 AI 客户端认识它。**找到你用的那一个,照着做就行。**

### Claude Desktop —— 只有它显示得出花生的界面

时间轴、逐条预览、换画面的缩略图网格,只有 Claude Desktop 能显示。

1. 下载 **[huasheng.mcpb](https://github.com/superlcr/huasheng-cli/releases/latest/download/huasheng.mcpb)**
2. **双击**它,Claude Desktop 会弹出安装窗口,点「安装」
3. 它会问 `hs` 装在哪 —— 默认已经填好 `~/.local/bin/hs`,直接确认即可

> **为什么还要填一次路径**:Claude Desktop 不读终端的 PATH。
> 改过安装位置的话,终端里跑 `which hs`(Windows 用 `where hs`)看到的就是要填的。
> 首次安装会提示这个包未签名,选择继续即可。

### Claude Code

```bash
claude plugin marketplace add superlcr/huasheng-cli
claude plugin install huasheng@huasheng
```

### Codex

```bash
codex plugin marketplace add superlcr/huasheng-cli
codex plugin add huasheng@huasheng
```

> 两个终端客户端**显示不了可视化卡片**(它们没有这个能力,不是配置问题)。
> 你会拿到文字回答,挑素材时附带候选画面的缩略图 —— 够用,只是没有界面。

### 其它客户端

任何支持 MCP 的客户端,手工加这一段:

```json
{"mcpServers": {"huasheng": {"command": "hs", "args": ["mcp", "serve"]}}}
```

### 装好了怎么确认

新开一个对话,问一句:

> 花生里我还有多少花生米?

第一次会让你在浏览器里点一下授权,**只需一次** —— 而且和命令行共用同一份登录态,
你在终端 `hs login` 过的话这步都省了。之后直接说人话就行:

> 用花生做一条 30 秒的视频,讲讲为什么天是蓝的

> 🔴 **只有两个动作会弹确认框**:确认分镜方案(扣花生米,不退)和投稿(发公网)。
> 其余改动服务端都存了档,退得回来。

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
| `hs mg` | MG 动画:显示 / 隐藏(内容改不了,用 `hs chat` 让 agent 改) |
| `hs snapshot` | 存档点:回退 / 重做 / 跳到某条指令之前 |
| `hs export` | 导出成片到本地 |
| `hs publish` | 投稿到 B 站(**唯一会把内容发到公网的命令**) |
| `hs fast` | 快速通道:排队排不动时的出口 |
| `hs mcp` | 以 MCP server 方式运行,给 AI 客户端用 |
| `hs upgrade` | 升级到最新版 |

`hs --help` 看总览,`hs help <命令>` 看单条命令的完整参数。

## 给脚本与 AI 客户端

每条命令加 `--json` 即输出结构化对象,字段一律 `snake_case`。

**成功**时直接就是数据:

```console
$ hs project show --json
{"pid": 123456789012345, "state": "READY", ...}
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

> ⚠ **`hs make` 有它自己的一套退出码**,不是上面这三个:
> `0` 成片 · `3` 停在报价(没给 `--yes`)· `4` 失败 · `5` 撞了兜底上限 · `6` 花生米不够。
> 批量跑的时候 `3` 和 `6` 都不是「坏了」,分别是「等人点头」和「等充值」。
> 完整说明见 `hs help make`。

### 三条容易搞错的约定

> **`CONFIRM_REQUIRED` 的正确反应是回头问人**,不是自己加 `--yes` 重试。
> `next_command` 是给**人点头之后**照抄用的。
>
> **分镜写操作返回 `applied: false` 不是失败**,是还在后台执行。
>
> **`hs wait` 返回 `timed_out: true` 不是失败**,再调一次接着等。

完整约定见 `hs help json`。

### 接进 AI 客户端(MCP)

**怎么装见上面「[在 AI 客户端里用](#在-ai-客户端里用)」**,这里只说能力边界。

凭据与命令行**共用同一份** `~/.hs/credentials.json` —— 你在终端登录过,AI 那边就能直接用;
没登录的话它会引导你登录,server 本身照常起得来。

MCP 覆盖的是**主干**(建项目 → 等 → 回答 → 确认 → 改分镜 → 导出 → 投稿),不是 `hs` 的全部
能力:分镜增删拆合、素材库、创作偏好、快照只在命令行里有 —— 它们要么要看着画面判断,
要么本来就是人的活。工具的出入参里只有 `pid` 和分镜序号,别的 id 一概不出现。

> 🔴 **只有两个工具会花钱或不可撤销**:确认分镜方案(扣花生米)、投稿(发公网)。
> 它们标了 `destructiveHint`,客户端会为它们弹确认框,代价写在工具标题上。
> 其余写操作服务端都存了档,退得回来。

详见 `hs help mcp`。

### 怎么指一个项目 / 一条分镜

项目一律用 **`pid`**(15 位,`hs project ls` 里那个)—— 所有命令的 `--pid`、所有 `--json` 里的
`pid` 字段都是同一个数。

分镜有两种指法,`hs clip --clip` 两种都收:**序号**(1、2、3…,人看着方便,但会随增删拆合变动)
和 **`clip_id`**(9 位,稳定不变,在 `hs clip ls --json` 的 `clips[].clip_id`)。脚本里请用后者。

详见 `hs help ids`。

## 凭据与隐私

`hs` 要用你的 B 站账号,所以先把这件事说清楚。

**登录怎么发生的**:`hs auth login` 会打开浏览器,你在 B 站的授权页上用密码 / 短信 /
扫码任选一种登录并点「授权」。**`hs` 全程不接触你的密码**,风控验证码也在网页上完成。
授权成功后浏览器回跳到本机的 `127.0.0.1` 回调端口,`hs` 拿到凭据。

**存在哪儿**:

| 文件 | 内容 | 说明 |
| :--- | :--- | :--- |
| `~/.hs/credentials.json` | 登录凭据(明文,权限 `0600`) | 有效期 180 天;`hs auth logout` 会删掉它 |
| `~/.hs/state.json` | `hs use` 记住的 pid、`hs make` 的续跑参数 | 不含凭据;`logout` **不会**清它 |

用 `HS_CREDENTIALS_FILE` / `HS_STATE_FILE` 可以改这两个位置(CI、容器里 home 不可写时用)。

**会连哪些地方**:只有花生的服务和 B 站的登录 / 投稿接口 —— 都是完成你敲的那条命令
所必需的。**没有独立的遥测通道,不做后台自动更新检查**,不在你没敲命令的时候联网。

**我们能看到什么**:请求的 `User-Agent` 里带四样东西 —— 版本、你用的是命令行还是 MCP、
平台、以及**命令名本身**(如 `project create`、`huasheng_create_video`):

```
hs/0.1.0 (cli; darwin-arm64; project create)
```

这是我们了解「哪个版本还有人用、要不要继续维护」的**唯一**手段,搭在本来就要发的请求上,
不额外联网。**里面绝不会出现你的内容** —— 文稿、项目标题、pid、文件名一律不进去;
命令名走白名单,认不出来就留空。

**⚠ `logout` 不等于「让已经泄漏的凭据失效」**:它退的是 hs 这一次的登录,而已经被复制
出去的凭据仍然可用。凭据万一泄漏,要去 B 站账号安全页**退出全部设备 / 改密码**。

**⚠ 你的文稿和素材会上传给花生**用于生成视频,这和你在网页版花生上创作是同一回事。
`hs publish --submit` 是**唯一**会把内容发到公网的命令,而且必须显式给 `--yes`。

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
