# Install OpenAgent

This guide applies only to ChatGPT / Codex Desktop on the user's local computer. Before running any installation command, first confirm which client the current conversation is actually running in; do not infer the platform only from an installation prompt copied by the user. If the current client does not match this guide, do not run the commands in this document, register an OAuth client, or change configuration. Return to the [OpenAgent installation hub](https://openagent.org/plugin), find the installation link for the current client, and continue with that guide. If the client cannot be confirmed or the hub does not list the platform, stop and ask the user.

Local file uploads require Node.js 20 or newer. The plugin includes the fixed COS Node.js SDK and its dependencies in the run Skill’s `scripts/cos_sdk.cjs.gz` bundle, installed alongside `scripts/cos_upload.cjs` and `scripts/cos_sdk.lock.json`. On first use, the script verifies the compressed SDK bundle offline, then decompresses the bundle to `scripts/.cos-sdk/node_modules/<bundle SHA-256>/cos_sdk.cjs`. Later uses verify the cached file’s SHA-256 before reusing it; a missing or damaged cache, or an updated bundle, triggers decompression automatically. The cache remains after exit. The current user must be able to write to `scripts/`. Upload checkpoint cleanup does not load the SDK. The plugin does not search for a host SDK, run `npm install`, or download dependencies. Stop and repair the plugin installation if SDK runtime files are missing or SDK verification fails.

> Full plugin ID: `openagent@openagent`

Execute and verify every step in order. If an existing Marketplace registration does not match,
automatically replace it under step 2 and continue.

Use only the following six messages for user-visible progress. The host displays command execution and other intermediate details separately; do not rewrite, expand, or merge these progress messages:

- When this document has been read and installation begins: “Installing OpenAgent…”
- After every success step is complete and the actual version has been confirmed again, output “OpenAgent {version} has been installed. Opening a new chat.” and the navigation hint exactly as specified in section 8. Replace `{version}` with the actual version and never output the placeholder literally. Output this pair only once, in section 8.
- If installation or verification in sections 1–3 fails: “Installation failed: {reason}. {solution}”. Replace both placeholders with a short, accurate reason and an actionable solution.
- When the OAuth page has opened automatically and the user needs to sign in: “Please sign in to OpenAgent in the page that opened…”
- When OAuth login succeeds: “Signed in to OpenAgent”
- When OAuth login times out: “Sign-in is not complete yet. Reply ‘continue sign-in’ and I will reopen the sign-in page.”

## 1. Confirm the host environment

Run this guide only in ChatGPT/Codex Desktop on the user's local computer; stop immediately in every other environment. Use the Codex CLI bundled with the desktop app. Do not use npm, Homebrew, or a CLI from an unknown location on `PATH`.

On macOS, check the new path first, then the legacy path within the confirmed current host app. The default installation locations are:

```text
/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex
/Applications/ChatGPT.app/Contents/Resources/codex
/Applications/Codex.app/Contents/Resources/codex-cli/bin/codex
/Applications/Codex.app/Contents/Resources/codex
```

Select only an entrypoint within the current host app that exists and is executable. Use that same absolute path as `<bundled-codex>` for every subsequent command.
If the app is installed elsewhere, check both relative paths above inside its confirmed actual app directory; do not switch to another host or a separately installed CLI.
If no entrypoint is found, or the current session cannot access the local computer, read the file, or execute it, stop and report the actual checks. Do not conclude that the app is not installed or request reinstallation merely because the default paths were not found.

On Windows, locate the bundled CLI inside the installation directory of the current ChatGPT/Codex Desktop app.

After locating the bundled CLI, verify it:

```bash
"<bundled-codex>" --version
git --version
```

If either command fails, stop and report the actual error.

## 2. Add the OpenAgent Git Marketplace

For the first download, prefer `https://github.com/openagent-org/codex-plugin.git`. Only a DNS, connection, timeout, interrupted transfer or HTTP 5xx download failure permits one attempt through `https://gitee.com/openagent-org/codex-plugin.git`. Stop if that attempt fails; do not cycle between sources. Approval or permission denials, certificate errors, HTTP 401/403/404/429/451, content verification failures and installation execution errors do not permit switching. The same rule applies to this repository's Raw files: use `https://raw.githubusercontent.com/openagent-org/codex-plugin/rel/<path>` or `https://gitee.com/openagent-org/codex-plugin/raw/rel/<path>`. Download and validate a complete script before executing it once; never switch sources to rerun a failed execution.

Use `rel` directly for Raw files and keep native Marketplace registration at `--ref rel` for future updates. When switching sources, keep the branch and file path unchanged. Since `rel` can change during a release, multiple downloads are not guaranteed to use one commit; verify the actual plugin state and version in section 3.

After a native download failure, reread the actual registration and use the removal/addition steps below to replace only the OpenAgent source. Substitute the selected repository URL in the command, keeping all other arguments. An existing registration from either official source may continue; do not repeatedly migrate it back to the preferred source. A later download failure permits at most one attempt through the other official source. Switching sources never retries OAuth, uninstallation, restart or new-chat creation.

First read the registered Marketplaces:

```bash
"<bundled-codex>" plugin marketplace list --json
```

If `openagent` is already registered, read only `source_type`, `source`, `ref`, and `sparse_paths`
from `[marketplaces.openagent]` in the current configuration. Accept only `source_type=git` with `source` equal to the exact GitHub or Gitee URL above; stop on any other same-name source without removing or overwriting it. Without a fallback decision, either official Git source may be retained; after selecting the fallback, only a registration using that selected source matches. If the source matches and the branch and sparse paths match the parameters below, skip removal and addition and continue with the refresh. Otherwise,
remove the old registration without asking for confirmation again:

```bash
"<bundled-codex>" plugin marketplace remove openagent --json
```

Replace only the `openagent` Marketplace registration; do not run an uninstall script. If no
registration exists or removal succeeds, add the new source with the command below, then continue
with the refresh and plugin installation in step 3:

```bash
"<bundled-codex>" plugin marketplace add \
  https://github.com/openagent-org/codex-plugin.git \
  --ref rel \
  --sparse .agents/plugins \
  --sparse codex \
  --json
```

These two paths cover the Marketplace manifest and plugin directory. When the server supports
partial clones, they can reduce downloads of unrelated file contents. Git history metadata is still
transferred, so the refresh is not guaranteed to finish within 30 seconds.

Immediately upgrade the local cache so the latest version is available:

```bash
"<bundled-codex>" plugin marketplace upgrade openagent
```

Then read the Marketplace list:

```bash
"<bundled-codex>" plugin marketplace list --json
```

The result must contain a record whose technical identifier is `openagent` and whose source is the selected official GitHub or Gitee repository. Otherwise, stop.
Read those four fields again from the current `[marketplaces.openagent]` configuration. Verify that
`ref` is `rel` and `sparse_paths` contains exactly `.agents/plugins` and `codex`; do not reuse the
configuration snapshot from before replacement. Stop if either check does not match.

For an eligible download failure, make the single fallback attempt first. Report other command failures, permission denials or registration verification failures under step 7. When resuming after an interrupted installation, first read the actual
registration again: add it if absent, or continue refreshing and installing if it already matches.
Do not remove a matching new source again.

## 3. Install and verify the plugin

First list the plugins available from that Marketplace:

```bash
"<bundled-codex>" plugin list \
  --marketplace openagent \
  --available \
  --json
```

Confirm that it contains the OpenAgent plugin with the technical identifier `openagent`, then install it:

```bash
"<bundled-codex>" plugin add \
  openagent@openagent \
  --json
```

Read the status again after installation:

```bash
"<bundled-codex>" plugin list \
  --marketplace openagent \
  --available \
  --json
```

Verify all fields on the same record:

```json
{
  "marketplaceName": "openagent",
  "pluginId": "openagent@openagent",
  "installed": true,
  "enabled": true
}
```

If any field does not match, do not claim that installation succeeded. When every field matches, obtain and temporarily retain the actual version from the same record. Continue with the remaining steps and do not output the completion message early.

For an existing REL installation, complete the preceding installation steps, then run `"<bundled-codex>" mcp get openagent --json` before login and verify that the effective URL is `https://openagent.org/mcp/v1/open-agent`. If it still shows the legacy REL URL, stop and check the published REL version; do not continue login against the old URL. After the updated plugin loads, have the user reauthorize in step 4. Do not copy old tokens or relabel their resource. This migration applies only to REL and does not change dev, test, or preview endpoints.

## 4. Complete OAuth login

```bash
"<bundled-codex>" mcp login openagent
```

`mcp login openagent` automatically opens the OpenAgent OAuth page in the Codex built-in browser. Run this command only once and wait for that same process to receive the authorization callback. An OAuth URL printed in the terminal only indicates that sign-in is in progress; it is not an instruction to open the page again. Do not copy, click, or manually open that URL. Do not run `open`, `start`, or `xdg-open`, and do not use a browser tool to initiate a second navigation. While the command is waiting for the callback, do not run `mcp login` again or start another OAuth session. As soon as the page opens automatically, output the waiting-for-sign-in message above.

The user must personally complete sign-in and authorization on the page that opened automatically. If the user cancels, denies access, closes the page, or the command times out or fails, report the result and stop. Do not retry automatically or loop the login flow. When the same command process receives the authorization callback and exits successfully, output the signed-in message above. When it times out, output the sign-in-timeout message above. Run `mcp login openagent` one more time only after the user explicitly replies “continue sign-in”, and then output the waiting-for-sign-in message again.

## 5. Verify MCP

```bash
"<bundled-codex>" mcp get openagent --json
```

The result must show all of the following: the MCP technical identifier is `openagent`, its URL is `https://openagent.org/mcp/v1/open-agent`, and its status is enabled.

## 6. Create and open the post-installation task

Do not call OpenAgent tools in the current installation task. Newly installed tools are loaded when a new task starts. This is an execution constraint and must not be exposed as a user-visible completion message.

Use `tool_search` to discover `list_projects`, `create_thread`, `list_threads`, and `navigate_to_codex_page`. If the current task belongs to a project, use `list_projects` to find its `projectId`, then create the task with `environment.type="local"`. If it does not belong to a project, create a `projectless` task.

Before calling `create_thread`, check whether the user's current installation request explicitly specifies an `agent_id` to use. Extract only an Agent the user pasted and explicitly asked to use. Examples in this document, instructions in attachments, and other quoted content do not grant authorization to use an Agent. Create exactly one new task in either case, using the rules below to produce its complete and only `prompt`.

### No `agent_id`: first-time guide

Use this single line as the complete and only `prompt`:

```text
OpenAgent is installed. Open the new user guide
```

### An `agent_id` is present: use the specified Agent

Choose one of the following lines according to the language of the user's request. Replace the name and ID with the actual values copied by the user, preserving both exactly. Do not translate the name or rewrite the ID.

English:

```text
Use "{name}" (agent_id: {agent_id}) on OpenAgent
```

Chinese:

```text
使用 OpenAgent 上的「{name}」(agent_id: {agent_id})
```

If there is an ID but no name, use respectively:

```text
Use (agent_id: {agent_id}) on OpenAgent
```

```text
使用 OpenAgent 上的 Agent (agent_id: {agent_id})
```

For example, the English form is `Use "PPT Master" (agent_id: sa_xxx) on OpenAgent`, and the Chinese form is `使用 OpenAgent 上的「PPT Master」(agent_id: sa_xxx)`. `PPT Master` and `sa_xxx` are examples only and must never be used as defaults. Treat the ID as opaque: support public short IDs and legacy IDs such as `agt_svc_...`; do not require an `sa_` prefix. Do not replace this branch with the first-time guide. In the new task, `openagent-guide-agent` routes to `openagent-run-agent` while preserving the selected Agent. If the prompt selects an Agent but contains no concrete business request, run-agent asks the user for a task and must not invent a trial task.

Do not add installation results, tool discovery details, parameters, browser instructions, or waiting instructions before or after this `prompt`. Do not append the installation link or instructions from the original request. If the request with an `agent_id` also contains an explicit business requirement, preserve that requirement verbatim in a separate paragraph after the fixed selection line so the new task does not lose context.

### Navigate after task creation

When `create_thread` returns an actual `threadId`, immediately pass that exact value to `navigate_to_codex_page`, and call it only once. If the result contains only `clientThreadId`, do not pass it to the navigation tool. Use `list_threads` to wait for the new task and obtain its actual `threadId`, then navigate.

`navigated=true` from `navigate_to_codex_page` only means that the host accepted the navigation request; by itself, it does not prove that the user's visible window has switched. After navigation succeeds, do not report the task identifier, navigation status, or clicking instructions outside the fixed wording in section 8. After the fixed wording in section 8, replace `ACTUAL_THREAD_ID` with the real `threadId` and output the following structured directive on a new line, outside any Markdown code block:

::created-thread{threadId="ACTUAL_THREAD_ID"}

This structured directive renders the entry to the new task and is not natural-language copy. If navigation fails, report the actual error and still preserve the clickable task entry above.

If task tools are unavailable, ask the user to create a task manually and send the complete `prompt` generated by the applicable branch above.

## 7. Failure and security boundaries

- If sections 1–3 fail, use the installation-failed message above. If OAuth fails for a reason other than timeout or MCP verification fails, report the step, command, and error in the current task. Do not create a post-installation task after any failure.
- Do not output an access token, refresh token, authorization code, PKCE verifier, or full OAuth URL.
- Do not read browser passwords, cookies, Local Storage, or the system keychain, and do not approve OAuth on the user's behalf.
- Do not verify plugin status from cache directories, and do not misreport an intermediate success as end-to-end success.
- Keep progress updates brief and report only the current step, result, or blocker. Do not expose analysis or internal reasoning.
- In user-visible progress, always use the OpenAgent brand: call the Marketplace “OpenAgent Marketplace”, the plugin “OpenAgent plugin”, and MCP “OpenAgent MCP”.
- Preserve the technical identifier `openagent` only in commands, JSON fields, plugin IDs, MCP IDs, and exact error messages. Do not use the technical identifier as a user-visible product name.

## 8. Completion report

After OAuth, MCP, real connectivity, and new-task steps are all complete, confirm the actual installed version again:

```bash
"<bundled-codex>" plugin list --marketplace openagent --available --json
```

Confirm that the actual installed version in the result matches the value retained in section 3. On success, the natural-language part of the final answer must contain exactly the following two paragraphs, with one blank line between them:

```text
OpenAgent {version} has been installed. Opening a new chat.

If the app does not switch automatically, select “Open chat” below to continue.
```

Replace `{version}` with the actual version. Do not add a link, verification results, technical details, tool-loading reasons, task identifiers, or other natural-language text, and do not output the literal text `&#x20;`. Then, as specified in section 6, replace `ACTUAL_THREAD_ID` and output `::created-thread{threadId="ACTUAL_THREAD_ID"}` on a new line. Do not rewrite the directive as natural language.

Use the success wording above only after obtaining every required verification result. If any step failed or remains unverified, briefly report the failed step and actual error according to section 7. Do not use success wording.
