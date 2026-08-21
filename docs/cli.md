# hs CLI 使用指南

本页适合直接运行 `hs` 命令的人。第一次安装、登录以及 AI 客户端接入见[主 README](../README.md)。

## 一条命令做完整片

```bash
hs make --script "介绍杭州西湖的三个冷知识" --yes --out ./out.mp4
```

`hs make` 会自动回答 agent 的反问、确认方案、等待成片并下载到本地。`--yes` 必须显式给出,
因为确认方案会扣除花生米且不可逆;不给就停在报价那一步。`--script` 也接受文件:
`--script @script.txt`。

## 分步控制

```bash
hs project create --script "…"   # 建项目,拿到 pid
hs use <pid>                     # 记住当前项目

hs wait                          # 等到下一个需要决策的时刻
hs chat answer "选第二个方案"      # 回答 agent 的反问
hs plan show --cost              # 查看分镜方案和价格
hs plan confirm --yes            # 确认开始成片(★ 扣花生米)

hs clip ls                       # 看所有分镜
hs clip edit --clip 3 --text "…" # 改第 3 个分镜的口播
hs settings                      # 列出全部呈现设置
hs settings subtitle-size 42     # 调字号

hs export get --out ./out.mp4    # 导出到本地
hs publish --submit --title "…"  # 投稿到 B 站
```

## 项目状态

```text
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

`hs wait` 会一直等到 `PAUSED` / `PLAN_READY` / `READY` / `FAILED` 之一。每条命令的返回里
也有 `next_actions`,告诉你下一步能做什么。

## 命令一览

| 命令 | 用途 |
| :--- | :--- |
| `hs auth` | 登录 / 查看状态 / 退出 |
| `hs account` | 花生米余额 |
| `hs make` | 一句话或一份文稿生成完整视频 |
| `hs project` | 建项目 / 看状态 / 列表 / 删除 |
| `hs use` | 记住当前项目 |
| `hs wait` | 等到下一个需要决策的时刻 |
| `hs plan` | 查看分镜方案 / 确认成片 |
| `hs chat` | 回答反问 / 提要求 / 看事件流 |
| `hs clip` | 改口播 / 增删 / 拆合 / 换素材 / 字幕 |
| `hs settings` | 画幅 / 音色 / 语速 / 字幕 / BGM |
| `hs voice` | 查看可用音色 |
| `hs pref` | 管理个人创作偏好 |
| `hs material` | 登记公网素材 / 管理素材文件夹 |
| `hs mg` | 显示 / 隐藏 MG 动画 |
| `hs snapshot` | 存档点 / 回退 / 重做 |
| `hs export` | 导出成片到本地 |
| `hs publish` | 投稿到 B 站(**会发到公网**) |
| `hs fast` | 使用快速通道 |
| `hs mcp` | 作为 MCP server 运行,供 AI 客户端调用 |
| `hs upgrade` | 升级到最新版 |

`hs --help` 看总览,`hs help <命令>` 看某组命令的参数、输出、错误和例子。

