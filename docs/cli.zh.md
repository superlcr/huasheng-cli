# hs CLI 使用指南

**简体中文** · [English](cli.md)

本页适合直接运行 `hs` 命令的人。第一次安装、登录以及 AI 客户端接入见[主 README](../README.zh.md);
`--json`、退出码与批量任务见[脚本与自动化](automation.zh.md)。

下面每条命令都接受 `--json`;`hs help <命令>` 会打印这条命令的完整参考 —— 参数、输出结构、
错误码和例子。

## 最快的一条:一句命令

```bash
hs make --script "杭州西湖的三个冷知识" --yes --out ./out.mp4
```

`hs make` 把整条流程替你跑完:回答 AI 导演的提问、确认分镜方案、等待成片、下载文件。

```bash
hs make --script @script.txt --yes --out ./video.mp4        # 文稿从文件读
hs make --script "三十秒讲清宋代点茶" --mode mg --yes        # 走动画,不走实拍素材
hs make --pid 123456789012345 --yes                         # 从上次停下的地方接着做
```

`--mode` 决定怎么做:`clip` 用实拍素材剪,`mg` 配动画,`auto`(默认)交给花生判断。

**`--yes` 不是客套。** 确认分镜要花积分且不可撤销,所以不带 `--yes` 时命令会停在报价那一步、
先把价钱给你看。中途停在任何地方,它都会打印出**从这里接着走的那条完整命令** ——
照抄那一行,别重跑你最初那条。

## 一步一步来

`hs make` 就是把下面这些步骤跑成一个循环。想先读分镜、改口播、调整观感再付钱,就自己走。

**1. 登录一次。** CLI 和所有 AI 客户端共用 `~/.hs/credentials.json`。

```bash
hs auth login
hs account          # 能看到积分余额就说明登录成功了
```

**2. 建项目并记住它。** `hs use` 存下项目 id,后面每条命令都可以省掉 `--pid`。

```bash
hs project create --script "杭州西湖的三个冷知识"
hs use 123456789012345
```

**3. 等它来找你。** 花生自己规划,遇到要你拿主意才停。`hs wait` 会一直等到那一刻。

```bash
hs wait                        # 在 PAUSED / PLAN_READY / READY / FAILED 返回
hs chat answer "轻快一点,节奏快些"
```

`hs chat send` 可以随时提要求,不必等它问;`hs chat history` 看之前都说过什么。

**4. 付钱之前先读分镜。**

```bash
hs plan show --cost            # 要做成什么样,以及要花多少
hs plan confirm --yes          # 花积分,开始成片
```

**5. 逐个分镜调整。** 成片是一镜一镜渲的,任何一镜都能返工。

```bash
hs clip ls                                   # 每一镜的时长、画面、口播首行
hs clip show --clip 3                        # 这一镜的完整口播和当前画面
hs clip edit --clip 3 --text "换一句口播"
hs clip split --clip 3 --at 2                # 在第 2 行之后把这一镜拆开
hs clip candidates --clip 3                  # 这一镜还有哪些画面可选
hs clip pick --clip 3 --candidate 2
```

**6. 定观感与声音。** 不带参数跑 `hs settings` 看全部;只给项名,它会告诉你这一项能填什么。

```bash
hs settings                                  # 所有项和当前值
hs settings bgm                              # 这一项能填什么
hs settings aspect 9:16
hs settings subtitle-size 42
```

**7. 交付。**

```bash
hs export get --out ./out.mp4                # 下载成片
hs publish --submit --title "西湖冷知识"      # 投稿到 B 站 —— 这一步是公开的
```

`hs publish` 是唯一会让内容变公开的命令。

## 项目状态

```text
create → PLANNING
       → PAUSED       等你回答                    → hs chat answer
       → PLANNING
       → PLAN_READY   等你确认                    → hs plan confirm --yes
       → PRODUCING
       → READY        可以导出或投稿了
```

| 状态 | 含义 | 该做什么 |
| :--- | :--- | :--- |
| `QUEUED` | 在排队 | `hs fast on` 可以插队 |
| `PLANNING` | 花生正在想或正在做 | 等 |
| `PAUSED` | **它问了你一个问题** | `hs chat answer "…"` |
| `PLAN_READY` | 分镜方案好了,此时还没扣过任何积分 | `hs plan show --cost`,然后 `hs plan confirm --yes` |
| `PRODUCING` | 正在一镜一镜渲染 | 等,或者先改已经好了的那几镜 |
| `READY` | 做完了 | `hs export get` 或 `hs publish` |
| `FAILED` | 出错了 | `hs project show` 的 `reason` 会说明原因 |

`hs wait` 会停在 `PAUSED`、`PLAN_READY`、`READY`、`FAILED` 四个状态。每条命令还会返回
`next_actions`,直接告诉你从当前位置能做什么。

## 命令参考

下面凡是要 `--pid` 的,跑过一次 `hs use <pid>` 之后都可以省掉。

### 登录与账户

| 命令 | 作用 |
| :--- | :--- |
| `hs auth login` | 用 B 站账号在浏览器里登录 |
| `hs auth status` | 看保存的登录态还有没有效 |
| `hs auth refresh` | 续期,不必重新登录 |
| `hs auth logout` | 清掉本地凭据 |
| `hs account` | 积分余额,按批次列出各自的过期时间 |

### 建项目与跟踪

| 命令 | 作用 |
| :--- | :--- |
| `hs project create --script <文本\|@文件>` | 建一个视频,打印它的 `pid` |
| `hs project show [--pid <pid>]` | 状态、设置,以及下一步能做什么 |
| `hs project ls [--limit 20]` | 最近的项目 |
| `hs project rm --pid <pid> --yes` | 删掉一个 |
| `hs use <pid>` / `hs use` / `hs use --clear` | 记住、查看、清除当前项目 |
| `hs wait [--until any\|plan\|paused\|done] [--timeout 60]` | 一直等到需要你拿主意 |
| `hs make …` | 以上全部一条命令跑完 —— 见上面的快速开始 |

### 和花生对话

| 命令 | 作用 |
| :--- | :--- |
| `hs chat answer <回答\|@文件> [--no-wait]` | 回答它正在等的那个问题 |
| `hs chat send <消息\|@文件>` | 随时提一个要求 |
| `hs chat cancel` / `hs chat retry` / `hs chat clear` | 中止当前这轮、重跑一次、清空对话 |
| `hs chat history [--limit 20]` | 之前说过什么 |
| `hs chat watch [--timeout 300]` | 实时跟着看它在做什么 |
| `hs chat cost [--run <run_id>]` | 某一轮花了多少 |

### 分镜方案与成片

| 命令 | 作用 |
| :--- | :--- |
| `hs plan show [--cost]` | 分镜方案;加 `--cost` 连报价一起看 |
| `hs plan confirm --yes` | 确认 —— **花积分,且不可撤销** |
| `hs fast` / `hs fast on [--yes]` / `hs fast off` | 查看、加入、退出快速通道 |

### 编辑分镜

| 命令 | 作用 |
| :--- | :--- |
| `hs clip ls` | 每一镜:时长、画面、口播首行 |
| `hs clip show --clip <#>` | 这一镜的全文 |
| `hs clip edit --clip <#> --text "…"` | 改口播 |
| `hs clip add --text "…" [--after <#>\|--before <#>]` | 插一镜 |
| `hs clip rm --clip <#>` | 删一镜 |
| `hs clip split --clip <#> --at <行号>` | 在某一行之后拆开 |
| `hs clip merge --clip <#> --into <#>` | 并成一镜 |
| `hs clip retry --clip <#>` | 重做失败的那一镜 |
| `hs clip dub --clip <#> [--undo]` | 单独重录这一镜的配音 |
| `hs clip candidates --clip <#> [--like <uuid>]` | 这一镜还有哪些画面可选 |
| `hs clip pick --clip <#> --candidate <#\|uuid>` | 换成其中一个 |
| `hs clip srt [--out <文件>]` | 导出 SRT 字幕 |

### 观感与声音

`hs settings` 只给项名不给值时,它会告诉你这一项能填什么;声音和音乐还会替你拉一份当前列表。

| 设置项 | 可填 |
| :--- | :--- |
| `aspect` | `16:9` 或 `9:16` |
| `voice` | 旁白音色,填 id 或名字(`hs voice ls` 列出全部) |
| `speed` | 语速,1.0 到 2.0 |
| `name` | 这个视频叫什么 |
| `subtitle` | on / off |
| `subtitle-size` | 22 / 32 / 42 / 54(预设会连描边一起设好) |
| `subtitle-color` | `#字色/#描边色`,或预设名 |
| `subtitle-outline` | 描边粗细,1 到 200 |
| `bgm` | 曲名、id,或 `off` |
| `bgm-volume` | 1 到 100 —— 要静音请用 `bgm off` |
| `voice-volume` | 0 到 100 |
| `auto-dub` | 改完口播是否自动重录:on / off |
| `sync` | 改完口播是否重新找画面:on / off |

换音色不会重录已经有的分镜,改语速也不会重渲它们。`hs` 每次都会说明这一点,并告诉你
怎么把改动应用到你在意的那一镜上。

`hs mg ls` / `hs mg show <id>` / `hs mg hide <id>` 控制动画的显示与隐藏,动画内容本身不在 CLI 里改。

### 自己的素材与偏好

| 命令 | 作用 |
| :--- | :--- |
| `hs material ls [--folder <id>] [--limit 20]` | 素材库 |
| `hs material add --url <公网地址> [--name …] [--duration …] [--folder <id>]` | 按 URL 登记一个素材 |
| `hs material rm <id,…>` | 删素材 |
| `hs material mkdir <名字>` | 建一个文件夹 |
| `hs material mv <id,…> --to <文件夹 id>` | 把素材移进去 |
| `hs material rename <文件夹 id> <新名字>` | 重命名文件夹 |
| `hs material rmdir <文件夹 id>` | 删掉文件夹 |
| `hs pref ls` / `hs pref show <id>` | 创作偏好 —— 它属于你,不属于某一个视频 |
| `hs pref add "名字" "内容"` / `hs pref edit <id>` / `hs pref rm <id>` | 增改删 |
| `hs voice ls` | 还没建视频时也能看的音色清单 |

用 `--material` / `--folder` 把素材推荐给花生**不等于强制它用**。

### 回退、交付与其它

| 命令 | 作用 |
| :--- | :--- |
| `hs snapshot ls` | 可以回到哪些时点 |
| `hs snapshot undo` / `hs snapshot redo` / `hs snapshot goto <s编号>` | 在这些时点之间移动 |
| `hs export start [--watermark]` / `hs export status --task <id>` / `hs export get [--out <文件>] [--timeout 300]` | 渲染并下载成片 |
| `hs publish --submit [--yes] [--title …] [--tag …] [--cover …]` | 投稿到 B 站 —— **这一步会公开** |
| `hs mcp serve` | 以 MCP server 方式运行,给 AI 客户端用 |
| `hs upgrade` | 重跑一次安装器,升到最新版 |

## 全局参数与环境变量

| 参数 | 含义 |
| :--- | :--- |
| `--json` | 结构化输出 —— 见[脚本与自动化](automation.zh.md) |
| `--pid <pid>` | 指定哪个视频;跑过 `hs use <pid>` 之后可以省 |
| `--no-color` | 纯文本、不上色(`NO_COLOR` 同样有效) |
| `--cookie <session>` | 覆盖已保存的登录态,开发用 |

`HS_COOKIE`、`HS_HOST`、`HS_CREDENTIALS_FILE`、`HS_STATE_FILE`、`HS_PID_REQUIRED`、
`HS_RATE_LIMIT_WAIT` 可以从环境变量覆盖同样这些东西。

## 接下来看哪里

- `hs help <命令>` —— 单条命令的完整参考,含 JSON 结构与错误码
- `hs help ids` —— 怎么指到一个视频、或指到某一镜
- `hs help json`、`hs help errors`、`hs help batch` —— 脚本化的完整契约
- [脚本与自动化](automation.zh.md) —— JSON、退出码、批量控制
- [登录、隐私与系统要求](security.zh.md) —— 凭据、联网范围、支持平台
