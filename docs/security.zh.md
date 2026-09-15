# 登录、隐私与系统要求

**简体中文** · [English](security.md)

本页说明 `hs` 如何登录、在本地保存什么以及会连接哪些服务。安装与使用入口见
[主 README](../README.zh.md)。

## 登录与本地文件

`hs auth login` 会打开 B 站授权页。密码、短信和风控验证码都只在网页中处理,`hs` 不接触密码。
授权完成后浏览器回到本机 `127.0.0.1` 回调端口。没有浏览器的机器上用 `hs auth login --no-browser`:
在别的设备上授权,再把浏览器跳到的地址粘回来。保存的登录态剩不到 7 天时会自动续期。

| 文件 | 内容 | 说明 |
| :--- | :--- | :--- |
| `~/.hs/credentials.json` | 登录凭据(权限 `0600`) | CLI 与所有 MCP 客户端共用;`hs auth logout` 会删除 |
| `~/.hs/device.json` | 登录、续期、退登时上报的设备标识(权限 `0600`) | 保存下来,容器重建后标识不变 |
| `~/.hs/state.json` | 当前 pid、`hs make` 续跑参数 | 不含凭据;退出登录不会删除 |
| `~/.hs/state.json.workflow.sqlite` | 各项目的恢复记录(`hs make` 与回答:哪次提交待确认/已收下、修复次数) | 不含凭据;用来在重启后避免重复提交 |
| `~/.hs/state.json.requests.sqlite` | 请求诊断:方法、路径、pid、run id、状态码与错误码、耗时 | 从不记录请求正文、cookie 与请求头;只保留最近 10 万条;`HS_DIAGNOSTICS=0` 关闭。只留在本机 |

CI 或容器中可以用 `HS_CREDENTIALS_FILE` / `HS_STATE_FILE` 更改位置。

## 网络与可观测信息

`hs` 只连接完成操作所需的花生服务和 B 站登录 / 投稿接口,没有独立遥测通道。唯一的例外是版本检查:
每天最多一次,跑命令、或 AI 客户端启动 `hs mcp serve` 时,它向 GitHub(`api.github.com`、`github.com`)
和 npm registry(`registry.npmjs.org`、`registry.npmmirror.com`)取最新版本号(`User-Agent` 里只带 hs 自己的版本),
有新版本就提示一句。它从不自己下载或安装任何东西,只有 `hs upgrade` 会从该版本的 GitHub release 下载并校验 SHA256
(装的是 GitHub release 上**安装包与 `SHA256SUMS` 都已就位**的最高版本;npm 上已发布、GitHub 文件还没传完的版本会跳过)。
校验和只防下载损坏或不完整:`SHA256SUMS` 与安装包同源 —— `HS_BASE_URL` 指向镜像时两者都由镜像提供,
镜像被篡改就能给出互相匹配的包和校验和。release 目前没有签名,`HS_BASE_URL` 只指向你信得过的镜像。
`HS_NO_UPDATE_CHECK=1` 关掉这个检查。正常请求的 `User-Agent` 会包含版本、CLI 或 MCP、平台和命令名,例如:

```text
hs/<版本号> (cli; darwin-arm64; project create)
hs/<版本号> (mcp; darwin-arm64; huasheng_create_project)
```

其中不包含文稿、标题、pid、文件名或素材内容。文稿、口播音频和素材会上传到花生用于生成视频;
只有 `hs publish --submit` 会把内容发布到公网。

`hs auth logout` 只删除本机凭据。凭据若已泄漏,请到 B 站账号安全页退出全部设备或修改密码。

## 系统要求

- macOS 11 及以上(Apple Silicon / Intel)
- Linux glibc 2.31 及以上
- Windows 10 及以上,x64;Windows on ARM 通过 x64 模拟层运行

