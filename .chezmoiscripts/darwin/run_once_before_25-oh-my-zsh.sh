#!/bin/bash
# Installs oh-my-zsh before dotfiles are written, so ours replaces its stock ~/.zshrc.
set -eu

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "==> Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
