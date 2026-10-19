#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# uninstall-openagent.sh
# 通过 Codex 原生 CLI 定向卸载 OpenAgent，保留其他插件。
# ============================================================

for arg in "$@"; do
  case "$arg" in
    --yes) ;; # 兼容原有管道命令；不增加交互确认。
    *) echo "❌ 不支持的参数：$arg（未执行卸载）" >&2; exit 1 ;;
  esac
done

# ---------- 发现 Codex CLI ----------
find_codex() {
  if [[ -n "${CODEX_CLI:-}" ]] && [[ -x "$CODEX_CLI" ]]; then
    echo "$CODEX_CLI"
    return
  fi
  # 同一桌面应用优先使用新版打包入口，再兼容旧版路径。
  for candidate in \
    /Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex \
    /Applications/ChatGPT.app/Contents/Resources/codex \
    /Applications/Codex.app/Contents/Resources/codex-cli/bin/codex \
    /Applications/Codex.app/Contents/Resources/codex; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
  if command -v codex >/dev/null 2>&1; then
    command -v codex
    return
  fi
  echo ""
}

CODEX="$(find_codex)"
if [[ -z "$CODEX" ]]; then
  echo "❌ 未找到 Codex CLI"
  exit 1
fi
echo ">>> Codex CLI: $CODEX"

if ! command -v node >/dev/null 2>&1; then
  echo "❌ 未找到 Node.js，请安装 Node.js 20+ 后重试（未执行卸载）" >&2
  exit 1
fi

# 内嵌 JSON 处理，保持 curl | bash 的单文件入口；不读取或手改凭据文件、TOML。
node - "$CODEX" <<'NODE'
const { spawnSync } = require('node:child_process');
const { lstatSync } = require('node:fs');
const { isAbsolute, join } = require('node:path');
const { homedir } = require('node:os');
const cli = process.argv[2];
const pluginId = 'openagent@openagent';
const sources = new Set([
  'https://github.com/openagent-org/codex-plugin.git',
  'https://oasn-ow.haimawan.com/git/openagent/codex-plugin.git',
]);
const mcpUrls = [
  'https://oasn-ow.haimawan.com/mcp/v1/open-agent',
  'https://oasn-test.haimawan.com/e/preview/mcp/v1/open-agent',
];
const cache = join(process.env.CODEX_HOME || join(homedir(), '.codex'), 'plugins/cache/openagent/openagent');

function run(label, args, json = false) {
  const result = spawnSync(cli, args, {
    encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: 60_000,
    // 原生插件说明可能超过 Node 默认的 1 MiB；stdout/stderr 均保留明确上限。
    maxBuffer: 16 * 1024 * 1024,
  });
  // MCP 输出可能含认证配置，不回显原始输出或错误正文。
  if (result.error || result.status !== 0) throw new Error(`${label}失败（CLI ${result.error?.code || `退出码 ${result.status ?? result.signal}`}）`);
  if (!json) return;
  try { return JSON.parse(result.stdout); }
  catch { throw new Error(`${label}未返回有效 JSON`); }
}

function marketplaces() {
  const data = run('读取 Marketplace', ['plugin', 'marketplace', 'list', '--json'], true);
  const rows = Array.isArray(data) ? data : data?.marketplaces;
  if (!Array.isArray(rows) || rows.some(m => typeof m?.name !== 'string')) throw new Error('Marketplace 状态格式不受支持');
  return rows;
}

function plugins() {
  const data = run('读取插件', ['plugin', 'list', '--marketplace', 'openagent', '--available', '--json'], true);
  let rows = data;
  if (!Array.isArray(data)) {
    if (!Array.isArray(data?.installed) || !Array.isArray(data?.available)) throw new Error('插件状态格式不受支持');
    rows = [...data.installed, ...data.available];
  }
  if (rows.some(p => typeof p?.pluginId !== 'string' || typeof p.marketplaceName !== 'string'
    || typeof p.installed !== 'boolean' || typeof p.enabled !== 'boolean')) throw new Error('插件状态格式不受支持');
  return rows;
}

function mcps() {
  const rows = run('读取 MCP', ['mcp', 'list', '--json'], true);
  if (!Array.isArray(rows) || rows.some(m => typeof m?.name !== 'string')) throw new Error('MCP 状态格式不受支持');
  return rows;
}

function checkSource(value) {
  if (value?.sourceType !== 'git' || !sources.has(value.source)) {
    throw new Error('同名 OpenAgent 的来源不是当前或迁移前的官方仓库，已停止清理');
  }
}

function verifyPluginRemoved() {
  if (plugins().some(p => p.pluginId === pluginId && (p.installed || p.enabled))) {
    throw new Error('OpenAgent 插件仍处于安装或启用状态');
  }
  verifyAbsent(cache, 'OpenAgent 插件缓存仍存在，未继续清理 Marketplace');
}

function verifyAbsent(path, message) {
  try { lstatSync(path); }
  catch (error) { if (error.code === 'ENOENT') return; throw error; }
  throw new Error(message);
}

try {
  console.log('>>> 检查 OpenAgent 来源与当前状态...');
  const market = marketplaces().find(m => m.name === 'openagent');
  const before = plugins();
  const mcp = mcps().find(m => m.name === 'openagent');
  if (market) {
    checkSource(market.marketplaceSource);
    if (typeof market.root !== 'string' || !isAbsolute(market.root)) throw new Error('Marketplace 缓存路径无效');
  }
  for (const plugin of before.filter(p => p.pluginId === pluginId)) checkSource(plugin.marketplaceSource);
  if (mcp && (mcp.transport?.type !== 'streamable_http' || !mcpUrls.includes(mcp.transport.url))) {
    throw new Error('同名 MCP 不是受支持的 OpenAgent 地址，已停止清理');
  }
  const shared = before.some(p => p.marketplaceName === 'openagent' && p.pluginId !== pluginId);

  console.log('>>> 清理 OpenAgent 本地 OAuth 登录...');
  // 禁用或已移除的插件不会出现在 MCP 列表中。临时覆盖只用于定位凭据，不写配置。
  for (const url of mcpUrls) {
    run('OpenAgent 本地 OAuth 登出', ['-c', `mcp_servers.openagent.url=${JSON.stringify(url)}`, 'mcp', 'logout', 'openagent']);
  }
  console.log('>>> 卸载 OpenAgent 插件及其缓存...');
  run('OpenAgent 插件卸载', ['plugin', 'remove', pluginId, '--json']);
  verifyPluginRemoved();
  console.log('>>> 移除 OpenAgent 独立 MCP 配置...');
  run('OpenAgent MCP 移除', ['mcp', 'remove', 'openagent']);
  if (mcps().some(m => m.name === 'openagent')) throw new Error('OpenAgent MCP 配置仍存在');
  if (market && !shared) {
    run('OpenAgent Marketplace 移除', ['plugin', 'marketplace', 'remove', 'openagent', '--json']);
    if (marketplaces().some(m => m.name === 'openagent')) throw new Error('OpenAgent Marketplace 登记仍存在');
    verifyAbsent(market.root, 'OpenAgent Marketplace 缓存仍存在');
  } else if (shared) {
    console.log('>>> 此 Marketplace 还包含其他插件，已保留。');
  }
  console.log('✅ OpenAgent 本地插件、MCP 配置和登录已清理，可以按安装指南重新安装。请重新打开桌面端。');
} catch (error) {
  console.error(`❌ OpenAgent 卸载未完成：${error.message}。修复原因后可重复运行；未执行全局缓存删除。`);
  process.exitCode = 1;
}
NODE
