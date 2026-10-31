#!/bin/bash
# macOS settings that are easy to forget, applied once on a fresh Mac (a
# migrated one brings them, and chezmoi's state, along). Change them in the UI
# afterwards; this never re-runs. Spaces settings need a logout to take effect.
set -eu

echo "==> Applying macOS settings"

# Holding a key repeats it instead of popping up the accent picker (vim hjkl)
defaults write -g ApplePressAndHoldEnabled -bool false

# Desktops stay in a fixed order and span all displays
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.spaces spans-displays -bool true

defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# iTerm2: default to the managed profile; let nvim copy over ssh (OSC 52)
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string 5E0D7A3C-2B51-4C1E-9F3A-6D2B8C4E1A70
defaults write com.googlecode.iterm2 AllowClipboardAccess -bool true

killall Finder Dock 2>/dev/null || true
