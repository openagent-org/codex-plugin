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

1. If this conversation has already confirmed successful sign-in for the same server and endpoint, but has not confirmed that the connection was rebuilt, go directly to Post-login Connection Recovery and skip login. A normal next turn or a user reply to continue is not evidence of a refreshed connection. Use the login path below for the actual failing connection. If the Host or this conversation already has a login in progress, keep its process or session handle and wait for that attempt, even if the user says “continue sign-in”; do not start another or repeat its messages. If the previous attempt's state cannot be confirmed, report that limitation without starting a new attempt.
2. Send the starting message immediately before launching login once. Keep and wait on the same process. A printed OAuth URL alone does not prove that the page opened; never reopen that URL. Show the waiting message only after confirmed opening and while authorization is still pending.
3. Confirm this attempt's authorization callback, token exchange, and successful login-command completion, then show the success message and perform the configuration check and Post-login Connection Recovery below. If the configuration check fails, report it separately and stop. Successful sign-in, valid configuration, and a refreshed active connection are distinct states; do not return to the original task until connection recovery is confirmed.
4. Cancellation, denial, reported page closure, opening failure, login failure, or confirmed OAuth timeout ends the attempt without retry. A short tool wait, a yielded process, or no new output is not an OAuth timeout; keep waiting on the same attempt. Report the actual result; only a confirmed OAuth timeout uses the fixed timeout message. If page closure is not observable, wait for the bounded timeout instead of claiming closure. A later explicit request to continue sign-in starts one fresh attempt only after the previous process is confirmed to have ended. Do not abandon or terminate a pending attempt just to start another.

## Login

Use the CLI bundled with the current ChatGPT/Codex desktop app, preserving its active profile. On macOS, find `Contents/Resources/codex-cli/bin/codex`, then `Contents/Resources/codex` inside that app; on Windows, use its bundled installation. Do not substitute a CLI from another app or an unknown PATH entry. If unavailable, report that limitation and stop.

Check `"<bundled-codex>" mcp get openagent --json` for the existing enabled server and its configured endpoint. Keep that endpoint; do not migrate environments. Then run `"<bundled-codex>" mcp login openagent` once and wait for its callback and successful exit. Use the Host's actual page-open and terminal results for the messages above.

The login command or Host owns opening the authorization page. Do not use `open`, `start`, `Start-Process`, `xdg-open`, `open_in_codex`, or any browser tool to open or reopen the OAuth URL, including to check whether it opened or to move it into another browser. If opening cannot be confirmed, report the uncertainty and wait on the same attempt; do not compensate with another navigation. This restriction applies to OAuth pages, not normal business browser handoffs.

After success, repeat `mcp get openagent --json` and verify the same server, endpoint, and enabled state. Do not invoke an account or business tool for verification.

## Post-login Connection Recovery

`mcp login` saves credentials but does not guarantee that an MCP connection already established in this conversation reloads them. `mcp get` only reads configuration and is not evidence of a refreshed connection.

1. Only if the current Host explicitly exposes an available MCP refresh or reconnect tool, invoke it once for the current OpenAgent connection under its actual contract and wait for confirmation that the connection was rebuilt. An accepted request or work scheduled for the next turn is not completion. Do not invent an `mcp reload` command, call the internal `config/mcpServer/reload` RPC directly, or start another app-server as a substitute for refreshing the current connection.
2. If the Host exposes no such entry, refreshing fails, or its result is unknown, end the current task turn and use the message matching `display_locale`: for `zh-CN`, “已登录 OpenAgent，但原任务尚未完成。请新建对话后继续此任务，让连接加载登录凭据；无需重复登录。”; for `en-US`, “Signed in to OpenAgent, but the original task is not complete. Please continue it in a new chat so the connection can load your credentials; you do not need to sign in again.” Do not retry the original business request on the old connection, call an account tool for verification, or substitute local execution. Do not automatically create a new chat. If the user continues in this conversation while connection rebuilding remains unconfirmed, repeat this message without starting OAuth again.
3. Only after the current OpenAgent connection is confirmed rebuilt, return control to the caller under the original task's authorization, idempotency, and failure rules. Do not issue extra account or business verification requests.
