# hs CLI 使用指南

**简体中文** · [English](cli.md)

本页适合直接运行 `hs` 命令的人。第一次安装、登录以及 AI 客户端接入见[主 README](../README.zh.md);
`--json`、退出码与批量任务见[脚本与自动化](automation.zh.md)。

下面每条命令都接受 `--json`;`hs help <命令>` 会打印这条命令的完整参考 —— 参数、输出结构、
错误码和例子。

## 最快的一条:一句命令

```bash
hs make --script "杭州西湖的三个冷知识" --out ./out.mp4
```

`hs make` 把整条流程替你跑完:回答 AI 导演的提问、确认分镜方案、等待成片、下载文件。

```bash
hs make --script @script.txt --out ./video.mp4        # 文稿从文件读
hs make --audio ./口播.m4a --out ./video.mp4          # 用自己录的口播做旁白
hs make --script "三十秒讲清宋代点茶" --mode mg        # 走动画,不走实拍素材
hs make --pid 123456789012345                         # 从上次停下的地方接着做
```

`--mode` 决定怎么做:`clip` 用实拍素材剪,`mg` 配动画,`auto`(默认)交给花生判断。

**`hs make` 会替你确认分镜方案,那一步要花积分。** 「一条命令」就是这个意思;它会打印出
这次确认花了多少。想在扣费之前先看方案和报价,走下面的分步做法 —— `hs make --pid <pid>`
能从任何一步接着往下跑。`make` 中途停在任何地方,都会打印出**从这里接着走的那条完整命令** ——
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
hs project create --audio ./口播.m4a                   # 音频模式;有逐字稿再加 --transcript @逐字稿.txt
hs use 123456789012345
```

**3. 等它来找你。** 花生自己规划,遇到要你拿主意才停。`hs wait` 会一直等到那一刻。

```bash
hs wait                        # 在 PAUSED / PLAN_READY / READY / FAILED 返回
hs chat answer "轻快一点,节奏快些"
```

`hs chat send` 可以随时提要求,不必等它问。说“这个”“这里”时,用 `--clip 3` 或
`--animation 2` 把当前分镜或 MG 动画一并传给花生;两个都不加就是针对整个项目。
`hs chat history` 看之前都说过什么。

```bash
hs chat send --clip 3 "给这段口播换一个更平静的画面"
hs chat send --animation 2 "把这个 MG 动画讲得更精炼"
```

**4. 付钱之前先读分镜。**

```bash
hs plan show --cost            # 要做成什么样,以及要花多少
hs plan confirm                # 花积分,开始成片 —— 并说出花了多少
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
hs publish --title "西湖冷知识"               # 看 --submit 会投出去的整份稿件;什么都不投
hs publish --submit --title "西湖冷知识"      # 投稿到 B 站 —— 这一步是公开的
```

`hs publish --submit` 是唯一会让内容变公开的命令。

## 项目状态

```text
create → PLANNING
       → PAUSED       等你回答                    → hs chat answer
       → PLANNING
       → PLAN_READY   等你确认                    → hs plan confirm
       → PRODUCING
       → READY        可以导出或投稿了
```

| 状态 | 含义 | 该做什么 |
| :--- | :--- | :--- |
| `QUEUED` | 在排队 | `hs fast on` 可以插队 |
| `PLANNING` | 花生正在想或正在做 | 等 |
| `PAUSED` | **它问了你一个问题** | `hs chat answer "…"`;若问的是「要不要照此方案开始制作」,用 `hs plan confirm` |
| `PLAN_READY` | 分镜方案好了,此时还没扣过任何积分 | `hs plan show --cost`,然后 `hs plan confirm` |
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
| `hs account bill [--pid <pid>] [--limit n] [--type all\|in\|out]` | 花生米账单,带逐项拆分 |

### 建项目与跟踪

| 命令 | 作用 |
| :--- | :--- |
| `hs project create --script <文本\|@文件>` | 建一个视频,打印它的 `pid` |
| `hs project create --audio <文件\|地址> [--transcript <文本\|@文件>]` | 音频模式:用自己录的口播(本机文件或公网地址)代替 `--script`。逐字稿可选,不给就由花生自己转写。上传由 `hs` 完成 |
| `hs project show [--pid <pid>]` | 状态、设置,以及下一步能做什么 |
| `hs project ls [--limit 20]` | 最近的项目 |
| `hs project rm --pid <pid>` | 删掉一个 —— 立刻删,不可恢复 |
| `hs use <pid>` / `hs use` / `hs use --clear` | 记住、查看、清除当前项目 |
| `hs wait [--until any\|plan\|paused\|done] [--timeout 60]` | 一直等到需要你拿主意 |
| `hs make …` | 以上全部一条命令跑完 —— 见上面的快速开始 |

### 和花生对话

| 命令 | 作用 |
| :--- | :--- |
| `hs chat answer <回答\|@文件> [--no-wait]` | 回答它正在等的那个问题 |
| `hs chat send [--clip N \| --animation N] [--attach <id\|文件\|地址> …] <消息\|@文件>` | 随时提要求,也可明确指向一项;`--attach`(最多 8 个)把素材库里的素材递给它 —— 给文件或地址会先加进素材库,和 `hs material add` 一样计费 |
| `hs chat cancel` / `hs chat retry` / `hs chat clear` | 中止当前这轮、重跑一次、清空对话 |
| `hs chat history [--limit 20] [--before <run_id>]` | 之前说过什么、每一轮改了什么;`--before` 往前翻页 |
| `hs chat watch [--timeout 300]` | 实时跟着看它在做什么 |
| `hs chat cost [--run <run_id>]` | 某一轮花了多少 |

### 分镜方案与成片

| 命令 | 作用 |
| :--- | :--- |
| `hs plan show [--cost]` | 分镜方案;加 `--cost` 连报价一起看 |
| `hs plan confirm` | 确认 —— **花积分,且不可撤销** |
| `hs fast` / `hs fast on` / `hs fast off` | 查看、加入、退出快速通道(`hs fast` 会说插队要花多少;已排上队之后 `on` 是单向的) |

### 编辑分镜

| 命令 | 作用 |
| :--- | :--- |
| `hs clip ls` | 每一镜:时长、画面、口播首行 |
| `hs clip show --clip <#>` | 这一镜的全文 |
| `hs clip edit --clip <#> --text "…"` | 改口播(之前标好的读音跟着词走,不会丢) |
| `hs clip edit --clip <#> --say "词=读音"` | 告诉旁白某个词怎么读(可重复;`--say -` 全部去掉) |
| `hs clip add --text "…" [--after <#>\|--before <#>]` | 插一镜 |
| `hs clip rm --clip <#>` | 删一镜 |
| `hs clip split --clip <#> --at <行号>` | 在某一行之后拆开 |
| `hs clip merge --clip <#> --into <#>` | 并成一镜 |
| `hs clip retry --clip <#>` | 重做失败的那一镜 |
| `hs clip dub --clip <#> [--text "…"] [--undo] [--cancel]` | 单独重录这一镜的配音;`--text` 只重录改动的字词;`--cancel` 停掉还在生成的那次 |
| `hs clip candidates --clip <#> [--like <uuid>] [--captions]` | 这一镜还有哪些画面可选;`--captions` 带上每段画面的内容描述 |
| `hs clip pick --clip <#> --candidate <#\|uuid>` | 换成其中一个 |
| `hs clip pick --clip <#> --file <mp4\|mov\|jpg\|png\|地址\|id> [--start <秒>] [--crop x,y,w,h]` | 改用你自己的画面 —— 免费;`--start` 指定从文件第几秒开始 |
| `hs clip srt [--out <文件>]` | 导出 SRT 字幕 |

### 观感与声音

`hs settings` 只给项名不给值时,它会告诉你这一项能填什么;声音和音乐还会替你拉一份当前列表。

| 设置项 | 可填 |
| :--- | :--- |
| `aspect` | `16:9` 或 `9:16` |
| `portrait-style` | 竖屏版怎么包装画面:`frame` / `blur` |
| `voice` | 旁白音色,填 id 或名字(`hs voice ls` 列出全部)。开始生产前免费,之后见下 |
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

**开始生产之后换音色**会把每个分镜重新配音、整片重新渲染,按字数扣花生米。
已扣花生米不退;完成后若有对应的历史版本,可以撤销修改,先用 `hs snapshot ls` 检查。
`hs settings voice <id> --cost` 只报价、什么都不改;不带 `--cost` 就真换,并一直等到所有分镜换完
(`--no-wait` 立刻返回,之后 `hs project show` 会一直显示 `voice_changing` 直到换完)。
用你自己录音做旁白的视频没有音色可换。

```bash
hs settings voice 磁性男音 --cost         # 「约 16 花生米(283 个计费字)」,什么都没改
hs settings voice 磁性男音                # 真换,并等分镜换完
hs settings voice 磁性男音 --no-wait      # 真换,回头再看
```

公共音色有 150 个左右,再加上你自己在网页上克隆的。每个都有名字和一句风格描述,
所以别翻,直接筛:

```bash
hs voice ls                  # 全部,默认音色会标出来
hs voice ls --search 温柔    # 名字、风格、id 都能匹配
hs voice ls --json           # 多给一个 preview_url,可以先听再选
```

凡是要填音色的地方,id 和名字都收;只写半个名字也行,只要它唯一命中一个音色。
命中多个时 `hs` 会把它们列出来让你按 id 挑 —— 它不会替你猜,因为选错音色意味着整片重录。

改语速会应用到之后的预览和导出,无需重新生成分镜。
`hs settings speed 1.3 --preview [--clip N]` 把一镜按这个语速渲染一段试听,什么都不改。

`hs mg ls` / `hs mg show <id>` / `hs mg hide <id>` 控制动画的显示与隐藏,`hs mg rm <id>` 彻底删掉一条;动画内容本身不在 CLI 里改。

### 自己的素材与偏好

| 命令 | 作用 |
| :--- | :--- |
| `hs material ls [--folder <id>] [--limit 20] [--status ready\|analysing\|uploaded\|failed] [--sort created\|updated] [--oldest]` | 素材库,可过滤、排序 |
| `hs material add <文件\|地址\|id …> [--name …] [--duration …] [--folder <id>]` | 加素材:本机文件、公网地址、或编辑时传过的文件的 id。视频要先被花生读一遍才能被选用,按秒计费;图片免费 |
| `hs material price <文件\|地址\|id …>` | 同样这些文件,`add` 会花多少 —— 什么都不加 |
| `hs material ls --uploads` | 编辑时传过的文件(花生没读过;`add <id>` 把它读进素材库) |
| `hs material rm <id,…>` | 删素材 |
| `hs material mkdir <名字>` | 建一个文件夹 |
| `hs material mv <id,…> --to <文件夹 id>` | 把素材移进去 |
| `hs material rename <文件夹 id> <新名字>` | 重命名文件夹 |
| `hs material rmdir <文件夹 id>` | 删掉文件夹 |
| `hs pref ls` / `hs pref show <id>` | 创作偏好 —— 它属于你,不属于某一个视频 |
| `hs pref add "名字" "内容"` / `hs pref edit <id>` / `hs pref rm <id>` | 增改删 |
| `hs voice ls [--search <文本>]` | 还没建视频时也能看的音色清单 |

用 `--material` / `--folder` 把素材推荐给花生**不等于强制它用**。

### 回退、交付与其它

| 命令 | 作用 |
| :--- | :--- |
| `hs snapshot ls` | 可以回到哪些时点 |
| `hs snapshot show <s编号>` | 只看某个时点长什么样,不跳过去 |
| `hs snapshot undo` / `hs snapshot redo` / `hs snapshot goto <s编号>` | 在这些时点之间移动 |
| `hs snapshot undo --run <run_id>` | 把花生某一轮做的事整个撤掉 |
| `hs export start [--watermark] [--ai-mark\|--no-ai-mark]` / `hs export status --task <id>` / `hs export get [--out <文件>] [--timeout 300]` | 渲染并下载成片。「AI生成」角标默认跟随你账号的设置,这两个参数可以改(`hs make --out` 和 `hs publish` 也收) |
| `hs publish [--title …] [--tag …] [--cover …] [--ai-label on\|off] [--set source=…]` | 投稿页链接,以及 `--submit` 会投出去的整份稿件;`--ai-label` 设 B 站的「AI 生成内容」声明(只有克隆音色的视频能改),转载必须给 `source` |
| `hs publish --submit [--title …] [--tag …] [--cover …]` | 投稿到 B 站 —— **这一步会公开,且不可撤销** |
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

## 积分与不可撤销的几步

命令做的就是动词说的那件事 —— 包括要花积分的时候,在这里那是常态 —— 做完会说花了多少,
不会问「你确定吗」。想先看再做,用对应的**只读命令**:

| 做之前… | 先看 |
| :--- | :--- |
| `hs material add` | `hs material price <同样的文件>` |
| `hs plan confirm` | `hs plan show --cost` |
| `hs fast on` | `hs fast` |
| `hs project rm` | `hs project show` |
| `hs publish --submit` | `hs publish`(同样的参数,什么都不投) |

四步撤不回:`hs plan confirm`、排队中的 `hs fast on`、`hs project rm`、`hs publish --submit`。
其余大多数操作按花生实际做的工作量收费,事前算不出;事后 `hs chat cost` 看这一轮花了多少,
`hs account` 看余额和会员状态;`hs account bill` 看米花哪了。

`hs` 不认识的参数一律报错,什么都不跑。

## 接下来看哪里

- `hs help <命令>` —— 单条命令的完整参考,含 JSON 结构与错误码
- `hs help ids` —— 怎么指到一个视频、或指到某一镜
- `hs help json`、`hs help errors`、`hs help batch` —— 脚本化的完整契约
- [脚本与自动化](automation.zh.md) —— JSON、退出码、批量控制
- [登录、隐私与系统要求](security.zh.md) —— 凭据、联网范围、支持平台
