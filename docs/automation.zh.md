# 脚本与自动化

**简体中文** · [English](automation.md)

本页说明如何稳定地从脚本、CI 或批量任务调用 `hs`。人工操作与 AI 客户端接入见
[主 README](../README.zh.md)。

## JSON 输出

每条命令加 `--json` 即输出结构化对象,字段一律为 `snake_case`。

成功时 stdout 直接是数据:

```console
$ hs project show --json
{"pid": 123456789012345, "state": "READY", ...}
```

失败时 stdout 是统一错误信封:

```json
{
  "error": {
    "code": "INSUFFICIENT_POINTS",
    "message": "...",
    "retryable": false,
    "suggested_action": "topup",
    "next_command": "hs make --pid ... --mode mg"
  }
}
```

- `suggested_action` ∈ `login` · `topup` · `retry` · `null`
- `next_command` 只在确实有一条可照抄命令时出现
- 普通命令退出码:`0` 成功 · `1` 命令失败 · `2` 用法错误
- `hs make` 退出码:`0` 成片 · `4` 失败 · `5` 达到兜底上限 · `6` 花生米不足

## 三条控制流约定

1. `hs` 不会问「你确定吗」。四条命令撤不回(`plan confirm` · `project rm` ·
   排队中的 `fast on` · `publish --submit`):跑之前**先**跟人确认。`hs help account` 里那几条
   只读命令能看到每一步会做什么、花多少。还有两处虽然能从存档点回退、但花生米扣了不退:生产后的
   `settings voice`(`--cost` 先报价)和给文件或地址的 `material add` / `chat send --attach`(`material price` 先报价)。
2. 分镜写操作返回 `applied: false` 表示仍在后台执行,不是失败。
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

`REPAIR_CONTINUATION_UNCERTAIN` 表示修复已尝试提交，但尚未确认进展。CLI 在重启后保留已使用的修复次数，不会对同一个尚未确认的 run 重复提交修复。请先查看项目状态和对话记录。

修复同时受 `--max-repairs` 总次数、`--max-stalled-repairs`（默认连续 3 轮没有新增完成分镜）和 `--max-repair-seconds`（默认累计 make 运行观察 3600 秒，不含两次运行之间的离线时间）约束。计数跨重启保留；排队和运行中的任务继续等待，不算失败轮次。`REPAIR_STALLED`、`REPAIR_TIME_LIMIT` 表示停止追加自动修复，请检查未完成分镜后再调整上限。

`HS_PROGRESS=1 hs make ... --json` 在 stderr 输出带版本号的 `hs.progress` JSON 进度事件，stdout 仍只有最终结果。这是 CLI 轮询观察到的进度，不是花生主动推送的订阅。

`REPAIR_CONTINUATION_UNCERTAIN` 保留结果未明的修复，并附查看对话的命令。明确的鉴权或配额拒绝允许稍后重试；响应丢失不能作为再修一次的依据。回答不同：花生对同一批问题只收一次答案，所以响应丢失后下一次会照常重发。`ANSWER_CONTINUATION_UNCERTAIN` 表示答案已被收下（或重发被拒、说明之前那次已生效），但问题还没翻篇——等待即可，不要再答。`hs make` 遇到这种情况会继续等，不会停下。`REPAIR_STALLED` 和 `REPAIR_TIME_LIMIT` 返回退出码 5，续跑命令会明确提高已耗尽的限制；执行前应检查项目。成片成功会清除旧修复窗口。
