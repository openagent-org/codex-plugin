# OpenAgent for Codex

Discover and run AI Agents from OpenAgent directly in Codex.

## Install

Ask Codex to read the [English installation guide](./INSTALL.en.md) or the
[Chinese installation guide](./INSTALL.md) and follow its instructions.

```text
Read https://raw.githubusercontent.com/openagent-org/codex-plugin/rel/INSTALL.en.md and follow the instructions to install OpenAgent.
```

The plugin ID is `openagent@openagent`. Installation uses the `rel` branch and
the production OpenAgent service. Complete the browser sign-in when prompted.
Node.js 20 or later is required for local file uploads.

## Use

Tell Codex what you want to do, for example:

- Find an Agent that can help with my task.
- Open OpenAgent and show me available Agents.
- Run this Agent with the attached file.
- Check my OpenAgent balance.

## Uninstall

Quit the Codex / ChatGPT desktop app and any CLI sessions using OpenAgent, then
run this in your terminal. A local Codex CLI and Node.js 20 or later are required.

```bash
curl -fsSL --proto '=https' --proto-redir '=https' 'https://raw.githubusercontent.com/openagent-org/codex-plugin/rel/uninstall-openagent.sh' | bash -s -- --yes
```

The script removes the official OpenAgent plugin, its local sign-in state and
associated configuration through the native Codex CLI. It preserves unrelated
plugins and configuration. If it fails, resolve the reported error before retrying.
