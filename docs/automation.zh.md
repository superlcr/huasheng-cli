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
    "code": "CONFIRM_REQUIRED",
    "message": "...",
    "retryable": false,
    "suggested_action": "confirm",
    "next_command": "hs plan confirm --pid ... --yes"
  }
}
```

- `suggested_action` ∈ `login` · `topup` · `retry` · `confirm` · `null`
- `next_command` 只在确实有一条可照抄命令时出现
- 普通命令退出码:`0` 成功 · `1` 命令失败 · `2` 用法错误
- `hs make` 退出码:`0` 成片 · `3` 等确认 · `4` 失败 · `5` 达到兜底上限 · `6` 花生米不足

## 三条控制流约定

1. `CONFIRM_REQUIRED` 应停下来问人,不能自动加 `--yes`。
2. 分镜写操作返回 `applied: false` 表示仍在后台执行,不是失败。
3. `hs wait` 返回 `timed_out: true` 表示本轮等待结束,再次调用即可。

完整字段与批量约定见 `hs help json`、`hs help errors`、`hs help batch`。

## 项目与分镜 ID

项目统一使用 15 位 `pid`。分镜可以用从 1 开始的序号,也可以用稳定的 9 位 `clip_id`。
增删或拆合分镜后序号会变化,自动化脚本应优先使用 `clip_id`。

详见 `hs help ids`。

