# OpenAgent for Codex

Discover and run AI Agents from OpenAgent directly in Codex.

## Install

Ask Codex to read the [English installation guide](./INSTALL.en.md) or the
[Chinese installation guide](./INSTALL.md) and follow its instructions.

```text
Read https://raw.githubusercontent.com/openagent-org/codex-plugin/rel/INSTALL.en.md and follow the instructions to install OpenAgent. If that download fails due to DNS, connection, timeout, interrupted transfer or HTTP 5xx, try https://gitee.com/openagent-org/codex-plugin/raw/rel/INSTALL.en.md once; retain any already resolved commit SHA. Do not switch for permission, certificate or other HTTP errors.
```

The plugin ID is `openagent@openagent`. Installation uses the `rel` branch and
the production OpenAgent service. Complete the browser sign-in when prompted.
Node.js 20 or later is required for local file uploads. Downloads prefer GitHub,
with one Gitee fallback for network failures under the installation guide’s rules;
keep the same resolved commit and never retry script execution or sign-in.

## Use

Tell Codex what you want to do, for example:

- Find an Agent that can help with my task.
- Open OpenAgent and show me available Agents.
- Run this Agent with the attached file.
- Check my OpenAgent balance.

## Uninstall

Quit the Codex / ChatGPT desktop app and any CLI sessions using OpenAgent, then
run this in your terminal. A local Codex CLI, Git and Node.js 20 or later are required.

```bash
(
  set -euo pipefail
  openagent_commit=$(git ls-remote --exit-code --refs https://github.com/openagent-org/codex-plugin.git refs/heads/rel | awk '$2 == "refs/heads/rel" { print $1 }')
  [[ "$openagent_commit" =~ ^[0-9a-f]{40}$ ]] || exit 1
  printf 'OpenAgent commit: %s\n' "$openagent_commit"
  openagent_script=$(mktemp) || exit
  trap 'rm -f "$openagent_script"' EXIT
  curl -fsSL --proto '=https' --proto-redir '=https' "https://raw.githubusercontent.com/openagent-org/codex-plugin/$openagent_commit/uninstall-openagent.sh" -o "$openagent_script" &&
    bash -n "$openagent_script" && bash "$openagent_script" --yes
)
```

The script removes the official OpenAgent plugin, its local sign-in state and
associated configuration through the native Codex CLI. It preserves unrelated
plugins and configuration. If it fails, resolve the reported error before retrying.

If the download fails for an eligible network reason, follow the guide to download
the printed commit from `https://gitee.com/openagent-org/codex-plugin/raw/<SHA>/uninstall-openagent.sh`,
then validate and execute the complete file once. If GitHub failed before resolving
a commit, Gitee may establish the initial SHA. Do not rerun a failed execution.
