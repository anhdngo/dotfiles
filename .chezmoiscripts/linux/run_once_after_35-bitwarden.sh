#!/bin/bash
# Installs the Bitwarden CLI (bw) into ~/.local/bin — groundwork for chezmoi
# secrets management (chezmoi has built-in bitwarden template functions).
set -eu

if command -v bw >/dev/null 2>&1; then
    exit 0
fi

echo "==> Installing Bitwarden CLI"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/bw.zip" "https://vault.bitwarden.com/download/?app=cli&platform=linux"
if command -v unzip >/dev/null 2>&1; then
    unzip -q "$tmp/bw.zip" -d "$HOME/.local/bin"
else
    bsdtar -xf "$tmp/bw.zip" -C "$HOME/.local/bin"
fi
chmod +x "$HOME/.local/bin/bw"
echo "Bitwarden CLI installed: log in with 'bw login'"
