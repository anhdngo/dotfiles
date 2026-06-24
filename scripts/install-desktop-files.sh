#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
APPS_DIR="$DOTFILES_DIR/applications"
ICONS_DIR="$APPS_DIR/icons"
DEST_APPS="$HOME/.local/share/applications"
DEST_ICONS="$HOME/.local/share/icons"

mkdir -p "$DEST_APPS" "$DEST_ICONS"

for desktop in "$APPS_DIR"/*.desktop; do
    name="$(basename "$desktop")"
    target="$DEST_APPS/$name"
    ln -sf "$desktop" "$target"
    echo "Linked $target"
done

for icon in "$ICONS_DIR"/*; do
    name="$(basename "$icon")"
    target="$DEST_ICONS/$name"
    ln -sf "$icon" "$target"
    echo "Linked $target"
done
