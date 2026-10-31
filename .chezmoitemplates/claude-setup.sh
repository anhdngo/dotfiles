#!/bin/bash
# Installs Claude Code and registers the MCP servers from
# .chezmoidata/claude.yaml at user scope. Re-runs when that list changes; only
# adds servers, so ones added by hand survive.
set -eu

export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

if ! command -v claude >/dev/null 2>&1; then
    echo "==> Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
fi

echo "==> Registering Claude Code MCP servers (user scope)"
{{ range $name, $cmd := .claude.mcps.stdio -}}
claude mcp get {{ $name }} >/dev/null 2>&1 || claude mcp add -s user {{ $name }} -- {{ $cmd }}
{{ end -}}
{{ range $name, $srv := .claude.mcps.remote -}}
claude mcp get {{ $name }} >/dev/null 2>&1 || claude mcp add -s user --transport {{ $srv.transport }} {{ $name }} {{ $srv.url }}
{{ end -}}
