# Quota Bar

一个轻量、原生的 macOS 菜单栏浮窗，用来查看 Codex、Claude Desktop / Code、Kimi Code、Antigravity（Gemini / Claude / GPT 模型）、Grok CLI 的剩余额度、DeepSeek API 余额与当前工作状态，支持应用内一键自动升级，还能把同样的信息推到备用手机或 ESP32 上。

A lightweight native macOS floating panel for Codex, Claude Code, Kimi Code, Antigravity (Gemini, Claude & GPT models) and Grok CLI quotas and work status, plus DeepSeek account balance — supports one-click built-in auto updates and mirrors everything to a spare phone or ESP32.

<img width="843" height="293" alt="image" src="https://github.com/user-attachments/assets/11484a74-5f22-4ed2-bb9c-87a9de099feb" />

## 功能 / Features

- **内置自动更新**：启动后静默检查 GitHub Releases 最新版本；设置面板与右键菜单新增「检查更新」/「更新到 vX.X.X…」，一键下载并自动重启升级，无需重新手动下载 DMG。
- **Antigravity 真实模型配额**：通过本地 Language Server 实时呈现 Gemini Models（Flash / Pro）与 Claude/GPT 模型的 5 小时滑动窗口与 7 天周额度，提供精确到分秒的重置倒计时与本地持久化缓存。
- **Codex 额度与余额**：兼容最新版 ChatGPT.app 与官方独立 CLI，支持 Pro/Prolite 等账户的 7 天/5 小时额度及 Credit 余额展示。
- 同屏展示各个服务的额度窗口、余额和重置时间，每个服务都用自己的品牌标识。
- 顶部菜单栏可切换 5 小时或周额度；卡片上的大数字始终跟随这个选择。
- 自动模式在宽屏显示完整摘要，小屏平滑循环滚动，也可强制选择完整或滚动方式。
- 左键显示/收起浮窗，右键打开更多操作；若顶部栏被 macOS 遮挡，可按 `⌥⌘Q` 恢复浮窗，也可在“应用程序”中再次打开 Quota Bar。
- 浮窗支持标准卡片和单行模式；红黄绿三色按钮分别用于隐藏、单行和恢复标准视图。
- **浮窗可以拖到屏幕最上边和最左边**，靠近边缘会自动贴齐，位置在重启后保留。
- **拖拽浮窗边缘即可调整宽高**，标准视图和单行模式各自记住尺寸；设置里可一键恢复默认。
- 标准视图使用自适应网格，服务多时自动换行。
- 模型管理支持排序、单独隐藏/显示；顶部栏、标准卡片和单行模式都会采用相同顺序。
- 模型管理可按服务暂停额度联网刷新，同时继续读取本机工作状态。
- **低额度提醒**：可设 5/10/20/30%，低于阈值时卡片、单行和菜单栏图标一起变色。
- **HUD 外接屏**：一键把额度推送到备用手机或 ESP32，详见 [`HUD/`](HUD/)。
- 深色高对比浮窗不会随浅色桌面或窗口背景变得难以阅读。
- DeepSeek 可通过官方 `/user/balance` 查看账户余额，API Key 仅保存于 macOS 钥匙串。
- 状态包括：等你审批、当牛马中、思考中、摸鱼中、未运行、需处理、已连接。
- 智能刷新默认在工作中每 30 秒检查一次，全部空闲时降到每 5 分钟。
- 可选 30 秒至 6 小时的预设、自定义 10–86400 秒（最长 24 小时），或完全手动刷新。
- 中文与 English 即时切换。
- 菜单栏常驻、跨桌面置顶、无需打开浏览器。

### 支持的服务 / Supported services

| 服务 | 额度来源 | 默认显示 |
| --- | --- | --- |
| Codex | 官方 app-server `account/rateLimits/read` | ✅ |
| Claude | Claude Desktop 本地用量历史 / Claude Code status line | ✅ |
| Kimi | Kimi Code 官方 `/usages` | ✅ |
| DeepSeek | 官方 `GET /user/balance`（需 API Key） | 需手动开启 |
| Antigravity | 本地 Language Server gRPC/HTTPS，实时读取 5 小时与周额度（支持 Gemini、Claude、GPT 模型） | 需手动开启 |
| Grok | 本机工作状态与所用模型（xAI 未公开额度接口） | 需手动开启 |

DeepSeek、Antigravity、Grok 默认隐藏，在浮窗的“模型管理”里打开即可。

## 零模型调用原则 / Zero model calls

Quota Bar **不会为了显示状态而消耗 Codex、Claude 或 Kimi 的模型额度**：

- Codex：通过官方 Codex app-server 的 `account/rateLimits/read` 读取当前登录账号的额度，并读取本地事件和任务进程判断工作状态。该接口不会生成模型回复。
- Claude Desktop：只读它维护的本地 `plan-usage-history.json`；Claude Code 使用官方 status line 与 **command hooks**。不会使用 prompt/agent hooks，也不会给 Claude 发送测试提示词。
- Kimi：读取本地会话事件；额度只通过 Kimi Code 官方 `/usages` HTTP 端点同步，不是模型生成请求。
- DeepSeek：只请求官方 `GET /user/balance` 账户余额接口，不调用对话或补全模型；隐藏后停止远程同步。
- Antigravity：通过本地 Antigravity Language Server 服务的 RetrieveUserQuotaSummary 读取真实的 Gemini Models 与 Claude/GPT 模型的 5 小时及周额度，完全本地读取，不发起模型推理调用，不消耗额外 Token。
- Grok：只读 `~/.grok` 里的本地配置和最近改动时间，完全不联网。
- HUD 外接屏复用浮窗已有的快照，不会产生任何额外请求。
- 不包含模型 SDK、遥测或第三方分析。

额度与工作状态采用不同边界：Codex 额度是账号级数据，同账号登录多台 Mac 时会各自从服务端刷新；“等你审批 / 当牛马中 / 摸鱼中”等状态只描述本机，不上传也不跨设备同步。

## 系统要求

- macOS 14 Sonoma 或更高版本
- Apple Silicon

当前 Release 使用 ad-hoc 临时签名，**未经过 Apple 公证**。请只从本仓库的官方 Releases 页面下载，并在安装前核对随包提供的 SHA-256 校验值。macOS 首次打开时会显示无法验证开发者的安全提示。

## 安装与升级

- **应用内自动升级**：已安装 Quota Bar 的用户（v1.3.2 及以上），可在顶部菜单栏右键点击「检查更新」，或打开设置面板点击更新，即可一键自动下载并重启完成升级，无需手动前往网页下载。
- **首次安装**：从 [Releases](https://github.com/pumpkinpieuncle/quota-bar/releases) 下载最新 DMG，将 `Quota Bar.app` 拖入 Applications。

### macOS 提示“无法验证开发者”

1. 先在“应用程序”中双击一次 `Quota Bar.app`，让 macOS 显示拦截提示；
2. 打开“系统设置”→“隐私与安全性”；
3. 向下滚动到“安全性”，找到 Quota Bar 的提示并点击“仍要打开”；
4. 在再次出现的确认框中点击“打开”，必要时输入 Mac 登录密码。

<img width="690" height="191" alt="image" src="https://github.com/user-attachments/assets/52544439-5706-405f-856c-0a070a5350be" />


macOS 会把这个版本保存为安全例外，之后可以正常双击打开。此操作只应在确认安装包来自本仓库且校验值一致时进行。详见 [Apple 官方说明](https://support.apple.com/102445)。

也可以从源码构建：

```bash
chmod +x scripts/*.sh
./scripts/build-app.sh
open "dist/Quota Bar.app"
```

安装到 `/Applications`：

```bash
./scripts/install-app.sh
```

旧的 `/Applications/Quota Bar.app` 会备份到 `dist/Quota Bar.previous.app`。

## Claude 额度与状态采集

Claude Desktop 安装后，Quota Bar 会自动读取它的本地套餐使用历史并显示 5 小时/7 天剩余额度。Claude Desktop 当前不会把精确重置时间写入本地历史，因此重置时间会在可由历史变化推断或 Claude Code status line 已提供时显示。

首次打开时，Claude 卡片会显示“启用零额度采集”。点击后，Quota Bar 会：

1. 备份现有的 `~/.claude/settings.json`；
2. 将应用内的 `QuotaBarCapture` 配置为 Claude 官方 status line；
3. 添加纯本地 command hooks，监听审批、工作、停止和空闲事件；
4. 只缓存模型名、rate limits、工作目录、会话 ID 和事件名，不保存提示词或回复正文。

重启 Claude Code，并完成一次正常请求后即可看到额度。采集不会主动发起 Claude 请求。

Claude 官方仅对 Claude.ai Pro/Max 订阅用户提供 `rate_limits` 字段，而且当前会话需要先完成一次正常 API 响应。Quota Bar 会显示 5 小时/7 天剩余额度与准确的重置时间；如果 status-line 命令路径因移动 App 而失效，再次点击“配置/修复零额度采集”即可更新路径。

如果已配置其他 status line，Quota Bar 不会覆盖它。可以在现有脚本中额外调用：

```bash
/Applications/Quota\ Bar.app/Contents/Helpers/QuotaBarCapture
```

注意：stdin 只能读取一次。已有脚本需要先把 stdin 保存到临时文件，再分别传给原逻辑和 `QuotaBarCapture`。

## HUD 外接屏 / HUD display

打开设置里的 “HUD 外接屏”，Quota Bar 会在本机起一个**只读**的小 HTTP 服务，
把浮窗上的数据同步给同一局域网里的设备：

- **备用手机 / 平板**：浏览器打开面板给出的网址即可，自适应竖横屏、支持屏幕常亮；
- **ESP32 + OLED**：仓库自带固件，读取 `/api/hud.txt` 这种单行文本，不需要 JSON 库。

服务只接受 `GET`，需要令牌，可以只监听本机，也可以随时换新令牌。完整说明、接口
文档和固件都在 [`HUD/`](HUD/) 目录里。

## 数据与隐私

- Claude/Kimi 的缓存位于 `~/.quotabar/`，权限为仅当前用户可读写。
- Kimi OAuth token 只在内存中发送到 Kimi 官方域名，不写入日志或 Quota Bar 缓存。
- DeepSeek API Key 只保存在 macOS 钥匙串中，并仅发送到 `api.deepseek.com/user/balance`。
- Claude 配置首次修改前会备份为 `~/.claude/settings.json.quotabar-backup`。
- HUD 外接屏默认关闭；打开后只监听局域网端口、只提供 `GET`，令牌可随时更换，任何设备都无法通过它改动 Mac 上的设置。

## 发布构建

```bash
./scripts/package-release.sh
```

脚本会生成 DMG、ZIP 和 SHA-256 校验文件到 `dist/release/v<version>/`。

正式发布需要钥匙串中的 `Developer ID Application` 证书，以及以下任一公证凭据：

- 本机 `QUOTABAR_NOTARY_PROFILE`（由 `notarytool store-credentials` 创建）；或
- `APPLE_ID`、`APPLE_APP_SPECIFIC_PASSWORD`、`APPLE_TEAM_ID`。

GitHub Actions 使用同名 secrets，并额外需要 base64 编码的 `DEVELOPER_ID_APPLICATION_P12` 与 `DEVELOPER_ID_APPLICATION_PASSWORD`。

## License

[MIT](LICENSE)
