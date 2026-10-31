#!/bin/bash
# Installs oh-my-zsh. Runs BEFORE dotfiles are written because the installer
# creates a stock ~/.zshrc — chezmoi overwrites it with ours right after.
# Unlike Linux there's no login shell to switch: macOS already defaults to
# /bin/zsh, and --unattended leaves it alone.
set -eu

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "==> Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
