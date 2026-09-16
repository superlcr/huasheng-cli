# 脚本与自动化

**简体中文** · [English](automation.md)

`hs wait --deadline 60 --json` 适合有限时长的轮询循环。成功读到状态后，到期仍未完成会正常返回（`timed_out: true`、`still_running: true`、退出码 0）；没读到状态或查询失败仍报错。给 AI 客户端使用时，deadline 应短于宿主的命令时限。

本页说明如何稳定地从脚本、CI 或批量任务调用 `hs`。人工操作与 AI 客户端接入见
[主 README](../README.zh.md)。

## JSON 输出

每条命令加 `--json` 即输出结构化对象,字段一律为 `snake_case`。以下契约是稳定的:只会加字段,
成功与失败的输出形状不变。

**成功**:stdout 直接是数据本身(没有信封):

```console
$ hs project show --json
{"pid": 123456789012345, "state": "READY", ...}
```

**失败**:退出码非 `0`,stderr 最后是一个 JSON 错误对象(`hs make` 在它之前可能写出以 `{"event":` 开头的单行事件):

```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "...",
    "retryable": true,
    "suggested_action": "retry",
    "next_command": "hs make --pid ... --mode mg",
    "retry_after_ms": 42000
  }
}
```

- `suggested_action` ∈ `login` · `topup` · `retry` · `null`
- `next_command` 只在确实有一条可照抄命令时出现(pid 已填好)
- `retry_after_ms`(`RATE_LIMITED`、`DAILY_LIMIT`、`RUN_CONCURRENCY_LIMIT`、可重试的 `PLAN_CONTINUATION_UNCERTAIN`)表示多久之后再试才有意义;`retry_at`(每日上限)是额度重置时刻,
  ISO 8601 带 `+08:00`
- 用法错误(没有这个命令 / 子命令 / 参数)同样是 JSON,code 为 `UNKNOWN_COMMAND` 或 `INVALID_INPUT`,退出码 `2`
- 本地已知有新版本时,JSON 对象(成功与失败)会多一个 `update: {latest, command}` 字段;只加字段,
  数组形状的输出不加

### 退出码

非 `0` 即失败,按 `!= 0` 判断的脚本不受影响。

| 码 | 含义 | 该怎么办 |
|---|---|---|
| `0` | 成功 | |
| `1` | 命令失败 | 看 `error.code` |
| `2` | 用法错误,什么都没跑 | 改命令行 |
| `4` | 仅 `hs make`:成片或导出失败,或下面没列出的其他失败 | 检查后 `resume` |
| `5` | make/export 达到 `--deadline`，或 wait 到期前未能取得状态；也包括 make 的安全上限或停滞 | 检查后 `resume` |
| `130` | Ctrl-C 停止本地等待；再按一次强制退出，不取消服务端任务 | 使用已记录的任务 ID 和恢复命令 |
| `143` | SIGTERM 停止本地等待，不取消服务端任务 | 使用已记录的任务 ID 和恢复命令 |
| `6` | 花生米不足、需要会员、或今日额度用完(`INSUFFICIENT_POINTS`、`VIP_REQUIRED`、`DAILY_LIMIT`、`MEMBERSHIP_OR_LIMIT_REQUIRED`) | 充值 / 等到 `retry_at` |
| `7` | 结果不明:`WRITE_OUTCOME_UNKNOWN`、`CREATE_OUTCOME_UNKNOWN`、`retryable: false` 的 `*_UNCERTAIN` | **先查状态再决定,别盲目重发** |
| `8` | 需要人来登录:`NO_CREDENTIAL`、`CREDENTIAL_EXPIRED`、`NOT_LOGGED_IN`、`CSRF_FAILED` | `hs auth login` |
| `9` | `ACCOUNT_RESTRICTED` 账号被风控限制 | 联系客服,重试没用 |
| `75` | 临时失败:`RATE_LIMITED`、`NETWORK_ERROR`、`RUN_CONCURRENCY_LIMIT`、`STREAM_IDLE`、`STREAM_INTERRUPTED`、`DOWNLOAD_TIMEOUT`、`CLIP_BUSY`、`CALL_BUDGET_EXHAUSTED`、可重试的 `HTTP_ERROR`、`suggested_action: "retry"` 的 `NOT_LOGGED_IN`(hs 已替你续上会话)、`retryable: true` 的 `*_UNCERTAIN`(如 `PLAN_CONTINUATION_UNCERTAIN`) | 稍后原样再跑,有 `retry_after_ms` 就等够再跑 |

其他错误码上的 `retryable: true`(如 `UPLOAD_FAILED` 或 `URL_UNREACHABLE`)表示再试可能有用,但退出码仍是 `1`(`hs make` 里是 `4`)。

### `hs make`

- 项目一建成,**stderr** 立刻输出一行
  `{"event":"hs.created","version":1,"at":...,"pid":...,"resume":"hs make --pid ..."[,"recovered":true]}`
  (总是输出,不依赖 `HS_PROGRESS=1`)。宿主超时杀掉进程时,跑 `resume` —— 绝不要重跑原命令,那会建第二个项目。
  `recovered: true` 表示花生没确认创建,hs 在最近的项目里找回了它,没有再建一个。
- stdout **只有**最终结果这一个 JSON(多行排版,请整体解析)。`hs make` 已经能报告某一步、而退出码非 `0` 时,
  它还带 `error`(与 stderr 上的同一个对象)和 `resume`;导出失败时旧的 `export_error` 字符串仍保留,旁边多一个 `error`。
- **`hs make` 在报告任何一步之前就停下时**(花生米、登录、创建结果不明、临时失败:退出码 `6`、`7`、`8`、`9`、`75`
  以及早期的 `4`),stdout **为空**,`{error, pid, resume}` 只在 stderr 上。一律从 stderr 读 `error`。
- `--json` 且 stderr 不是终端时,人读的过程行不输出:stderr 上是 `hs.created` 那一行(项目建成后)、
  失败时的 `{error, pid, resume}`,以及 `HS_PROGRESS=1` 时的 `hs.progress` 行。事件都是以 `{"event":` 开头的单行;
  错误对象总是最后写出。

### 进度事件

`HS_PROGRESS=1` 在 stderr 输出带版本号的 `{"event":"hs.progress","version":1,...}`:`hs make` 的进度,
以及任意命令等账号额度超过 5 秒时的 `kind: "rate_limit_wait"`。不带 `--json` 时,这类等待(以及等空闲任务位置)改为打印一行人读提示;带 `--json` 时什么都不打。

### 分镜编辑

所有输出模式下，分镜修改默认等到生效；`--no-wait` 表示提交被接受后返回。
`applied: false` 仍表示「还在跑」而不是失败,并附 `next_command`:一条只读的 `hs clip wait --pid ... --op ...`,用来稍后确认。
`hs wait` 给出 `retry_after_ms`(毫秒,排队时非零)和 `next_commands`:按执行顺序排列的命令列表 —— 没有可跑的就是空列表,遇到提问或需要继续等时一条,分镜方案待确认时两条(先 `hs plan show --cost`,再 `hs plan confirm`)。正因为最后这种情况它是复数;其余地方 hs 一律用单数的 `next_command`。

### 本版的破坏性变更

只判断 `!= 0` 的脚本不受影响。按具体退出码分支、逐行读 `hs make` 输出、或在非终端里跑分镜编辑的脚本,请核对下面几点。

**退出码。** 以前所有失败都是 `1`(`hs make` 里是 `4`;make 另有 `5` 表示 `REPAIR_STALLED` / `REPAIR_TIME_LIMIT`、`6` 表示花生米)。现在:

| 错误 | 以前 | 现在 |
|---|---|---|
| `hs make` 以外的 `INSUFFICIENT_POINTS`、`VIP_REQUIRED`、`DAILY_LIMIT` | `1` | `6`(`hs make` 里不变) |
| `MEMBERSHIP_OR_LIMIT_REQUIRED`(新) | — | `6` |
| `NO_CREDENTIAL`、`CREDENTIAL_EXPIRED`、`NOT_LOGGED_IN`、`CSRF_FAILED` | `1` / make `4` | `8` |
| `suggested_action: "retry"` 的 `NOT_LOGGED_IN` | `1` / make `4` | `75` |
| `ACCOUNT_RESTRICTED` | `1` / make `4` | `9` |
| `WRITE_OUTCOME_UNKNOWN`、`CREATE_OUTCOME_UNKNOWN`、`retryable: false` 的 `*_UNCERTAIN` | `1` / make `4` | `7` |
| `RATE_LIMITED`、`NETWORK_ERROR`、`STREAM_IDLE`、`STREAM_INTERRUPTED`、`DOWNLOAD_TIMEOUT`、`CLIP_BUSY`、`CALL_BUDGET_EXHAUSTED`、可重试的 `HTTP_ERROR`、`retryable: true` 的 `*_UNCERTAIN` | `1` / make `4` | `75` |
| `RUN_CONCURRENCY_LIMIT` | `1` / make `4` | `75` / make `5` |
| make 的 `REPAIR_STALLED`、`REPAIR_TIME_LIMIT` | `5` | 不再返回:这两种情况现在以 `MAKE_STALLED`(`5`)停下 |

`hs make` 的 `4` 现在只剩上表没列出的失败。`0`、`2` 以及 `hs make` 的 `5`、`6` 含义不变。

**分镜修改不再随输出模式改变执行。** 默认等到生效，`--no-wait` 在接受后返回，`--deadline` 限制整条命令总时长。

**`hs make` 在 stderr 上报「已建成」。** `hs.created` 那一行写在 stderr;stdout 仍然只有一个 JSON。pid 从那一行取,或取最终结果里的 `pid` / `resume`。

**多出来的字段。** 本地已知有新版本时 JSON 对象会带 `update: {latest, command}`;`hs wait` 新增 `needs_action`、`still_running`、`retry_after_ms` 和 `next_commands`。比对完整键集合的脚本要允许它们。

**等待更久。** 命令等账号额度最多 `HS_RATE_LIMIT_WAIT` 秒(默认改为 900,原来 30)。`hs plan confirm` 和 `hs chat send` 等待任务空位也计入总 `--deadline` 预算（默认 0，不限时）。`hs make` 在 `--stall-timeout`(默认 1800 秒)内看不到任何可见变化(分镜数、状态、run)就以退出码 `5`(`MAKE_STALLED`)停下;实时进度事件能延长这条线,但从上次可见变化算起最多到 3 倍 `--stall-timeout`;`hs wait` 遇到提问或待确认的分镜方案立刻返回,视频做完或失败时也返回。完整清单见发版说明。

## 三条控制流约定

1. `hs` 不会问「你确定吗」。四条命令撤不回(`plan confirm` · `project rm` ·
   排队中的 `fast on` · `publish --submit`):跑之前**先**跟人确认。`hs help account` 里那几条
   只读命令能看到每一步会做什么、花多少。还有两处虽然能从存档点回退、但花生米扣了不退:生产后的
   `settings voice`(`--cost` 先报价)和给文件或地址的 `material add` / `chat send --attach`(`material price` 先报价)。
2. 分镜写操作返回 `applied: false` 表示仍在后台执行,不是失败;照抄它的 `next_command` 确认。
3. `hs wait` 返回 `timed_out: true` 表示本轮等待结束,再次调用即可。

完整字段与批量约定见 `hs help json`、`hs help errors`、`hs help batch`。

## 项目与分镜 ID

项目统一使用 15 位 `pid`。分镜可以用从 1 开始的序号,也可以用稳定的 9 位 `clip_id`。
增删或拆合分镜后序号会变化,自动化脚本应优先使用 `clip_id`。

详见 `hs help ids`。



## 自动恢复与进度（高级）

默认无需配置。以下接口为自动化与已有脚本保留，普通创作不需要逐项设置。

`--max-questions` 只统计答题，不包含正常方案确认。`--max-continuations` 默认最多追加 3 次制作推进消息，在本机跨重启保留。达到 `CONTINUATION_LIMIT` 时保留项目，先检查对话，再明确提高上限；不会自动重建项目。

`PLAN_CONTINUATION_UNCERTAIN` 表示推进请求可能已经生效。先用 `hs chat history --pid <pid>` 和 `hs project show --pid <pid>` 核对，不要盲目重复发送。排队等待和进度轮询不消耗推进次数。

`REPAIR_CONTINUATION_UNCERTAIN` 表示修复已尝试提交，但尚未确认进展。CLI 在重启后保留已使用的修复次数，不会对同一个尚未确认的 run 重复提交修复。请先查看项目状态和对话记录。如果对话里失败之后没有新的一轮，说明修复没发到花生（例如 hs 恰好在发送前被杀）：用错误信息里给出的 `hs chat send --pid <pid> "…"` 自己发出，再续跑 `hs make`；新的一轮会解除这条记录。

`hs make` 只会因为下面几种原因停下，都是退出码 `5` 并给出续跑命令：花费上限 `--max-repairs`（自动修复次数，默认 3，`REPAIR_LIMIT`）、`--max-questions`（`QUESTION_LIMIT`）、`--max-continuations`（`CONTINUATION_LIMIT`），以及时间上限 `--stall-timeout`（`MAKE_STALLED`）和 `--deadline`（`DEADLINE_EXCEEDED`）。计数跨重启保留。一轮修复没有完成任何分镜、最后又失败，不算变化（修复中途有分镜完成就算），所以一直修不好的项目到 `--stall-timeout` 时以 `MAKE_STALLED` 停下，或更早在 `--max-repairs` 停下。排队和等空出任务位置的时间不计入。无效的 `--max-stalled-repairs`、`--max-repair-seconds` 已删除；不再返回 `REPAIR_STALLED`、`REPAIR_TIME_LIMIT`。

`HS_PROGRESS=1 hs make ... --json` 在 stderr 输出带版本号的 `hs.progress` JSON 进度事件，stdout 仍只有最终结果。这是 CLI 轮询观察到的进度，不是花生主动推送的订阅。

`REPAIR_CONTINUATION_UNCERTAIN` 保留结果未明的修复，并附查看对话的命令。明确的鉴权或配额拒绝允许稍后重试；响应丢失不能作为再修一次的依据。回答不同：花生对同一批问题只收一次答案，所以响应丢失后下一次会照常重发。`ANSWER_CONTINUATION_UNCERTAIN` 表示尚无法核实答案是否被收下；一次拒绝不能证明之前那次已生效。先查看对话并等待，再决定是否需要重新回答。`hs make` 遇到这种情况会继续等，不会停下。`REPAIR_LIMIT` 和 `MAKE_STALLED` 返回退出码 5 并给出续跑命令（`REPAIR_LIMIT` 时会写明更高的 `--max-repairs`）；执行前应检查项目。成片成功会清除旧修复窗口。

## MCP 重配音恢复

MCP 每次调用都有时间上限。调用 `huasheng_edit_clip` 的 `action: "redub"` 后保留 `action.operation.id`，用 `huasheng_wait_for_action` 查询。录音生成完成不等于已应用：出现 `action.next_call` 时，按其中的工具名和完整参数继续，用 `operation_id` 应用已有录音，不重新生成。工作台会自动完成续跑。等待工具不会应用音频；应用请求丢失响应时，通过原操作 ID 只读核验，不要重新发起录音来重试。

CLI 配音恢复使用只读的 `hs clip wait --pid PID --clip CLIP --op dub`。录音已生成但未应用时返回 `needs_action: true`、`done: false`，有本机任务记录时给出完整的 `hs clip dub --task <id>` 命令；无记录则提示检查分镜，不能仅凭缓存应用。只有实际音频匹配且合成完成，才算成功。

`RECORDING_PENDING`（退出码 1）表示已有未完成的本机录音任务，本次没有提交新录音。按返回的 `hs clip dub --pid <pid> --task <id>` 继续，或用 `hs clip dub --pid <pid> --clip <clip> --cancel` 丢弃待处理试听；不要原样重试新录音命令。 跟踪已有录音时，stderr 输出 `hs.operation_existing`；`hs.operation_started` 仅表示新操作已受理。

共享同一本机状态目录的 hs 调用不会同时为同一分镜提交两次配音：`CLIP_BUSY`（退出码 75）表示另一调用仍在提交。`ACTION_STATE_UNCERTAIN`（退出码 7）表示提交未获得已确认的回执；先检查分镜，再显式用 `--cancel` 丢弃待处理录音后重新生成。`ACTION_STATE_UNAVAILABLE`（退出码 1）表示本机任务记录无法读取或保存；恢复访问并检查远端状态后再决定是否重复写入。任务保存使用跨进程互斥，避免并发命令互相覆盖句柄。
