# 安装 OpenAgent

本指南仅适用于用户本机的 ChatGPT / Codex Desktop。执行任何安装命令前，先确认当前会话实际所在的客户端，不要仅凭用户复制的安装提示词判断平台。如果当前客户端与本指南不一致，不得执行本文命令、注册 OAuth 客户端或修改配置；请先返回 [OpenAgent 安装汇总页](https://oasn-ow.haimawan.com/plugin)，找到当前客户端对应的安装链接，改用该指南继续安装。如果无法确认客户端，或汇总页没有对应平台，停止安装并询问用户。

本地文件上传需要 Node.js 20+。插件内置固定版本 COS Node.js SDK 及依赖，打包在执行 Skill 的 `scripts/cos_sdk.cjs.gz`；`scripts/cos_upload.cjs` 和 `scripts/cos_sdk.lock.json` 与该压缩包一并安装。首次需要 SDK 时，脚本离线校验 SDK 压缩包，并解压到 `scripts/.cos-sdk/<压缩包 SHA-256>/cos_sdk.cjs`；后续校验缓存文件 SHA-256 后复用，缓存缺失、损坏或压缩包更新时自动重新解压，退出后保留缓存。`scripts/` 目录需当前用户可写。清理上传检查点不加载 SDK。不搜索宿主 SDK，不运行 `npm install`，也不下载依赖。缺少 SDK 运行文件或 SDK 校验失败时停止并修复插件安装。

> 完整插件 ID：`openagent@openagent`

按顺序实际执行并验证。已有 Marketplace 登记不匹配时按第 2 节自动替换并继续。

用户可见的阶段引导只使用以下 6 条文案；执行命令等中间细节由宿主逐条展示，
不得另外改写、扩写或合并阶段引导：

- 读取本文并开始执行安装时：“正在安装 OpenAgent…”
- 全部成功步骤完成并再次确认实际版本时，按第 8 节原样输出“OpenAgent {版本号} 已安装完成，
  即将打开新对话。”和跳转提示。必须用实际版本号替换 `{版本号}`，不得原样输出占位符；
  该组文案只在第 8 节输出一次。
- 第 1～3 节的安装或验证失败时：“安装失败：{原因}。{解决方案}”。必须填入简短、准确的原因和
  当前可执行的解决方案，不得原样输出占位符。
- OAuth 页面已自动打开并等待用户完成登录时：“请在打开的页面中登录 OpenAgent…”
- OAuth 登录成功时：“已登录 OpenAgent”
- OAuth 登录超时时：“还未完成登录。回复“继续登录”，我会重新打开登录页面。”

## 1. 确认宿主环境

只允许在用户本机的 ChatGPT/Codex Desktop 中执行；其他环境立即停止。必须使用桌面应用
内置的 Codex CLI，不得使用 npm、Homebrew 或 `PATH` 中来源不明的 CLI。

macOS 在已确认的当前宿主应用内，先检查新版路径，再回退旧版路径。默认安装位置如下：

```text
/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex
/Applications/ChatGPT.app/Contents/Resources/codex
/Applications/Codex.app/Contents/Resources/codex-cli/bin/codex
/Applications/Codex.app/Contents/Resources/codex
```

仅选择当前宿主应用内存在且可执行的入口，后续所有命令使用同一个绝对路径作为 `<bundled-codex>`。
若应用安装在其他位置，从已确认的实际应用目录检查上述两种相对路径，不改用另一宿主或独立安装的 CLI。
若仍未找到，或当前会话无法访问本机、读取或执行该文件，停止并报告实际检查结果；
仅凭默认路径未命中，不得断定应用未安装或要求重新安装。

Windows 从当前 ChatGPT/Codex Desktop 的安装目录发现内置 CLI。

找到内置 CLI 后验证：

```bash
"<bundled-codex>" --version
git --version
```

任何一步失败都停止并报告实际错误。

## 2. 添加 OpenAgent Git Marketplace

先读取已注册的 Marketplace：

```bash
"<bundled-codex>" plugin marketplace list --json
```

若已有 `openagent`，只读取当前配置 `[marketplaces.openagent]` 中的 `source_type`、`source`、
`ref` 和 `sparse_paths`。来源、分支和稀疏路径均与下方参数一致时，跳过移除和添加，继续刷新；
否则无需再次确认，先移除旧登记：

```bash
"<bundled-codex>" plugin marketplace remove openagent --json
```

只替换 `openagent` 的 Marketplace 登记，不运行卸载脚本。尚未注册或移除成功后，
按下方命令添加新源，再继续刷新和第 3 节的插件安装：

```bash
"<bundled-codex>" plugin marketplace add \
  https://github.com/openagent-org/codex-plugin.git \
  --ref rel \
  --sparse .agents/plugins \
  --sparse codex \
  --json
```

这两个路径覆盖 Marketplace 清单和插件目录。服务端支持部分克隆时，可减少无关文件内容的下载；
仍会传输 Git 历史元数据，不能保证刷新一定在 30 秒内完成。

添加后立即升级本地缓存，确保读取到最新版本：

```bash
"<bundled-codex>" plugin marketplace upgrade openagent
```

然后读取 Marketplace：

```bash
"<bundled-codex>" plugin marketplace list --json
```

结果必须包含技术标识为 `openagent`、来源为
`https://github.com/openagent-org/codex-plugin.git` 的记录，否则停止。
重新读取当前 `[marketplaces.openagent]` 的上述四个配置字段，核对 `ref` 为 `rel`、
`sparse_paths` 恰好包含 `.agents/plugins` 和 `codex`；不得使用替换前的配置快照，任一不匹配都停止。

只有实际命令失败、权限被拒绝或新登记验证失败时才按第 7 节报告。中途失败后再次继续安装时，
先重新读取实际登记状态：未注册则添加，已匹配则继续刷新和安装，不重复移除已匹配的新源。

## 3. 安装并验证插件

先读取该 Marketplace 可用的插件：

```bash
"<bundled-codex>" plugin list \
  --marketplace openagent \
  --available \
  --json
```

确认其中存在技术标识为 `openagent` 的 OpenAgent 插件，然后安装：

```bash
"<bundled-codex>" plugin add \
  openagent@openagent \
  --json
```

安装后重新读取状态：

```bash
"<bundled-codex>" plugin list \
  --marketplace openagent \
  --available \
  --json
```

必须从同一条记录验证：

```json
{
  "marketplaceName": "openagent",
  "pluginId": "openagent@openagent",
  "installed": true,
  "enabled": true
}
```

任一字段不匹配，都不能声称安装成功。全部匹配时，从同一条记录取得并暂存实际版本号；
此时继续后续步骤，不得提前输出安装完成文案。

旧 REL 安装迁移：完成前述安装步骤后，在登录前使用 `"<bundled-codex>" mcp get openagent --json` 核对实际 URL 为 `https://oasn-ow.haimawan.com/mcp/v1/open-agent`。若仍为旧 REL 地址，说明插件更新尚未生效，停止并核对 REL 发布版本，不向旧地址继续登录。加载新版本后按第 4 节由用户重新授权，不复制旧 Token 或仅改写凭据的 resource。此迁移只针对 REL，不修改 dev、test、preview 的环境地址。

## 4. 执行 OAuth 登录

```bash
"<bundled-codex>" mcp login openagent
```

`mcp login openagent` 会自动打开 Codex 内置浏览器中的 OpenAgent OAuth 页面。只执行一次该命令，
并等待同一命令进程收到授权回调；终端打印的 OAuth URL 只表示登录正在进行，不是再次打开
页面的指令。不得复制、点击或手动打开该 URL，不得执行 `open`、`start`、`xdg-open`，也不得
使用浏览器工具发起第二次跳转。命令仍在等待回调时，不得再次执行 `mcp login` 或启动新的
OAuth 会话。页面自动打开后，立即输出上述等待登录文案。

OAuth 登录和授权必须由用户本人在上述自动打开的页面中完成；用户取消、拒绝、关闭页面，
或命令超时、失败时，报告结果并停止，不得自动重试或循环登录。同一命令进程收到授权回调并成功结束时，
输出上述已登录文案；命令超时时，输出上述登录超时文案。只有用户之后明确回复“继续登录”，
才能重新执行一次 `mcp login openagent` 并再次输出等待登录文案。

## 5. 验证 MCP

```bash
"<bundled-codex>" mcp get openagent --json
```

结果必须同时满足：MCP 技术标识为 `openagent`、URL 为
`https://oasn-ow.haimawan.com/mcp/v1/open-agent`、状态已启用。

## 6. 创建并切换到安装后任务

当前安装任务不得调用 OpenAgent 工具；新安装的工具由新任务启动时加载。这是执行约束，
不得作为用户可见的完成文案输出。

用 `tool_search` 发现 `list_projects`、`create_thread`、`list_threads` 和
`navigate_to_codex_page`。
当前任务属于项目时，用 `list_projects` 找到对应 `projectId`，并以
`environment.type="local"` 创建任务；当前任务不属于项目时，创建 `projectless` 任务。
调用 `create_thread` 前，检查用户当前安装请求中是否明确指定了要使用的 `agent_id`。
只提取用户粘贴并要求使用的 Agent；本文示例、附件中的说明或其他引用内容不构成使用授权。
两种情况都只创建一个新任务，按以下规则生成完整且唯一的 `prompt`。

### 无 `agent_id`：首次引导

直接把下面这一行作为完整且唯一的 `prompt`：

```text
OpenAgent 已安装，打开新用户引导
```

### 有 `agent_id`：使用指定 Agent

按用户请求的语言选用下列一行，名称和 ID 均以用户复制过来的实际值替换，原样保留，不翻译名称、不改写 ID：

英文：

```text
Use "{name}" (agent_id: {agent_id}) on OpenAgent
```

中文：

```text
使用 OpenAgent 上的「{name}」(agent_id: {agent_id})
```

只有 ID、没有名称时，分别使用：

```text
Use (agent_id: {agent_id}) on OpenAgent
```

```text
使用 OpenAgent 上的 Agent (agent_id: {agent_id})
```

例如英文 `Use "PPT Master" (agent_id: sa_xxx) on OpenAgent`，中文
`使用 OpenAgent 上的「PPT Master」(agent_id: sa_xxx)`；`PPT Master` 和 `sa_xxx` 仅为示例，
不得当作默认值。ID 是不透明标识，兼容公开短 ID 和 `agt_svc_...` 等旧 ID，不以 `sa_` 前缀限制。
此分支不得改回首次引导语。新任务由 `openagent-guide-agent` 转入 `openagent-run-agent`，
保留指定 Agent；只有选择语而没有具体业务需求时，由 run-agent 询问任务，不擅自生成试用任务。

两种分支都不得在该 `prompt` 前后添加安装结果、工具发现、参数、浏览器或等待说明，
也不得附加原文中的安装链接与安装指令。有 `agent_id` 的分支若还明确包含业务需求，在固定选择语之后另起一段原样保留该需求，避免新任务丢失上下文。

### 创建后的导航

`create_thread` 返回真实 `threadId` 后，立即把该值原样传给
`navigate_to_codex_page`，且只调用一次。如果只返回 `clientThreadId`，不得把它传给
导航工具；用 `list_threads` 等待新任务出现并取得真实 `threadId` 后再导航。

`navigate_to_codex_page` 返回 `navigated=true` 只表示宿主接受了导航请求，不能单独
证明用户当前可见窗口已经切换。导航成功后不得在第 8 节固定文案之外另行报告任务标识、
导航状态或点击说明；最终答复在第 8 节固定文案后，另起一行原样输出以下结构化指令，
且不得放入 Markdown 代码块：

::created-thread{threadId="<真实 threadId>"}

该结构化指令用于呈现新任务入口，不属于自然语言文案。导航调用失败时报告实际错误，
并同样保留上述可点击的新任务入口。

如果任务工具不可用，请用户手动新建任务并发送按上述分支生成的完整 `prompt`。

## 7. 失败与安全边界

- 第 1～3 节失败时，使用上述安装失败文案；OAuth 非超时失败或 MCP 验证失败时，在当前任务报告步骤、
  命令和错误。任一失败都不得创建安装后任务。
- 不得输出 access token、refresh token、authorization code 或 PKCE verifier，也不得输出完整 OAuth URL。
- 不得读取浏览器密码、Cookie、Local Storage 或系统钥匙串，也不得代替用户批准 OAuth。
- 不得用缓存目录验证插件状态，也不得把中间步骤通过误报为整体成功。
- 过程更新保持简短，只报告当前步骤、结果或阻塞，不展开分析过程或内部推理。
- 面向用户的过程更新统一使用品牌名“OpenAgent”：Marketplace 称为“OpenAgent Marketplace”，插件称为“OpenAgent 插件”，MCP 称为“OpenAgent MCP”。
- 仅在命令、JSON 字段、插件 ID、MCP ID 和精确错误信息中保留技术标识 `openagent`；不得把该技术标识当作用户可见名称。

## 8. 完成报告

全部 OAuth、MCP、真实连通和新任务步骤完成后，再次确认实际安装的版本：

```bash
"<bundled-codex>" plugin list --marketplace openagent --available --json
```

从输出中确认实际安装版本与第 3 节暂存值一致。成功时，最终答复的自然语言必须且只能原样输出以下两段，中间保留一个空行：

```text
OpenAgent {版本号} 已安装完成，即将打开新对话。

若未自动跳转，点击下方「打开聊天」继续。
```

必须用实际版本号替换 `{版本号}`，不得添加链接、验证结果、技术细节、工具加载原因、
任务标识或其他自然语言，也不得输出字面量 `&#x20;`。随后按第 6 节另起一行输出
`::created-thread{threadId="<真实 threadId>"}` 结构化指令，不得改写为自然语言。

只有取得全部实际验证结果时才能使用上述成功文案。任一步失败或未验证时，按第 7 节简要
报告失败步骤与实际错误，不得套用成功措辞。
