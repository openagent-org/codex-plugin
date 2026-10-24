# OpenAgent runtime sign-in

## When to use

Use this only after an OpenAgent Tool or the Host explicitly reports missing or expired OpenAgent authentication, such as `MCP_AUTH_REQUIRED` or `MCP_TOKEN_INVALID`. A bare HTTP status, missing tool, insufficient scope, business error, or network failure is not enough. Do not check login before normal calls. Anonymous search, guide, and selection calls stay anonymous unless their supplied credentials are explicitly rejected.

This takes priority over the caller's failure, fallback, and completion rules. Headless or delegated calls return the trusted authentication failure to their caller; that caller owns the single login flow and user messages. This does not handle App-only tools.

## Flow and messages

Use `display_locale`; if unset, choose explicit preference > trusted Host locale > conversation language > `en-US`. Show only the matching column, without workflow labels.

| State | zh-CN | en-US |
| --- | --- | --- |
| Starting login | 需要登录 OpenAgent 才能继续。正在打开登录页面… | Please sign in to OpenAgent to continue. Opening the sign-in page… |
| Page opened, still waiting | 请在打开的页面中登录 OpenAgent… | Please sign in to OpenAgent in the page that opened… |
| Authorization confirmed | 已登录 OpenAgent | Signed in to OpenAgent |
| Timed out | 还未完成登录。回复“继续登录”，我会重新打开登录页面。 | Sign-in is not complete yet. Reply ‘continue sign-in’ and I will reopen the sign-in page. |

1. 若本对话已确认同一服务器和 endpoint 登录成功，但连接尚未确认重建，直接进入「登录后的连接恢复」，跳过登录；普通下一轮或用户回复“继续”不代表连接已刷新。Use the login path below for the actual failing connection. If the Host or this conversation already has a login in progress, keep its process or session handle and wait for that attempt, even if the user says “continue sign-in”; do not start another or repeat its messages. If the previous attempt's state cannot be confirmed, report that limitation without starting a new attempt.
2. Send the starting message immediately before launching login once. Keep and wait on the same process. A printed OAuth URL alone does not prove that the page opened; never reopen that URL. Show the waiting message only after confirmed opening and while authorization is still pending.
3. 确认本次授权回调、Token 交换和登录命令成功后，显示登录成功消息，完成下方配置检查及「登录后的连接恢复」。配置检查失败时单独报告并停止。登录成功、配置有效和当前连接已刷新是不同状态；未确认连接恢复时，不得返回原任务继续调用。
4. Cancellation, denial, reported page closure, opening failure, login failure, or confirmed OAuth timeout ends the attempt without retry. A short tool wait, a yielded process, or no new output is not an OAuth timeout; keep waiting on the same attempt. Report the actual result; only a confirmed OAuth timeout uses the fixed timeout message. If page closure is not observable, wait for the bounded timeout instead of claiming closure. A later explicit request to continue sign-in starts one fresh attempt only after the previous process is confirmed to have ended. Do not abandon or terminate a pending attempt just to start another.

## Login

Use the CLI bundled with the current ChatGPT/Codex desktop app, preserving its active profile. On macOS, find `Contents/Resources/codex-cli/bin/codex`, then `Contents/Resources/codex` inside that app; on Windows, use its bundled installation. Do not substitute a CLI from another app or an unknown PATH entry. If unavailable, report that limitation and stop.

Check `"<bundled-codex>" mcp get openagent --json` for the existing enabled server and its configured endpoint. Keep that endpoint; do not migrate environments. Then run `"<bundled-codex>" mcp login openagent` once and wait for its callback and successful exit. Use the Host's actual page-open and terminal results for the messages above.

The login command or Host owns opening the authorization page. Do not use `open`, `start`, `Start-Process`, `xdg-open`, `open_in_codex`, or any browser tool to open or reopen the OAuth URL, including to check whether it opened or to move it into another browser. If opening cannot be confirmed, report the uncertainty and wait on the same attempt; do not compensate with another navigation. This restriction applies to OAuth pages, not normal business browser handoffs.

After success, repeat `mcp get openagent --json` and verify the same server, endpoint, and enabled state. Do not invoke an account or business tool for verification.

## 登录后的连接恢复

`mcp login` 保存凭据，不保证当前对话已建立的 MCP 连接重新加载凭据；`mcp get` 只读取配置，不能作为连接已刷新的证据。

1. 仅当当前宿主明确提供可用的 MCP 刷新或重连工具时，按该工具的实际契约对当前 OpenAgent 连接执行一次，并等待连接重建的确认。仅受理或安排到下一轮的回执不算完成。不要臆造 `mcp reload` 命令、直接调用内部 `config/mcpServer/reload` RPC，或启动另一个 app-server 代替当前连接刷新。
2. 当前宿主未提供入口、刷新失败或结果未知时，结束本轮任务并按 `display_locale` 提示：`zh-CN`：已登录 OpenAgent，但原任务尚未完成。请新建对话后继续此任务，让连接加载登录凭据；无需重复登录。`en-US`：Signed in to OpenAgent, but the original task is not complete. Please continue it in a new chat so the connection can load your credentials; you do not need to sign in again. 不在旧连接上重试原业务、调用账号工具验证或改为本地代作；不自动创建新对话。若用户在本对话中继续，但连接仍未确认重建，重复上述提示，不再次启动 OAuth。
3. 只有当前 OpenAgent 连接已确认重建后，才返回调用方按原任务的授权、幂等和失败规则继续；不额外发起账号或业务验证请求。
