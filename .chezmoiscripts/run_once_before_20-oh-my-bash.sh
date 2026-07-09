#!/bin/bash
# Installs oh-my-bash if missing. Runs BEFORE dotfiles are written because the
# installer overwrites ~/.bashrc — chezmoi restores ours right after.
set -eu

if [ ! -d "$HOME/.oh-my-bash" ]; then
    echo "==> Installing oh-my-bash"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
fi
