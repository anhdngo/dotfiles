#!/bin/bash
# macOS settings, the counterpart of the GNOME dconf dumps: the same choices
# (dark mode, workspaces, file manager, terminal) where macOS has an equivalent.
# run_onchange: edit this file to change a setting and it re-runs. Some only
# take effect after logging out and back in (dark mode, Spaces across displays).
set -eu

echo "==> Applying macOS settings"

# --- system -------------------------------------------------------------------
# Dark mode (GNOME color-scheme='prefer-dark')
defaults write -g AppleInterfaceStyle -string Dark
# Holding a key repeats it instead of popping up the accent picker - vim's hjkl
# (and VS Code's vim mode) are unusable otherwise
defaults write -g ApplePressAndHoldEnabled -bool false
# Battery percentage in the menu bar (GNOME show-battery-percentage)
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

# --- workspaces ---------------------------------------------------------------
# Keep desktops in a fixed order, so Ctrl+Left/Right (and the mouse side
# buttons, see ~/.hammerspoon/init.lua) always land on the same one, like
# GNOME's static workspaces. macOS reorders them by recent use by default.
defaults write com.apple.dock mru-spaces -bool false
# One set of desktops across all displays (GNOME workspaces-only-on-primary=false)
defaults write com.apple.spaces spans-displays -bool true
# Tiled windows touch, no gaps between them (Tiling Shell inner/outer gaps 0)
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# --- Finder (the Nautilus settings) -------------------------------------------
# New windows open in ~ - also what Ctrl+Alt+E opens
defaults write com.apple.finder NewWindowTarget -string PfHm
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"
# Folders before files, as Nautilus and Explorer sort them
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search the current folder, not the whole Mac
defaults write com.apple.finder FXDefaultSearchScope -string SCcf
# Icon view (Nautilus default-folder-viewer='icon-view')
defaults write com.apple.finder FXPreferredViewStyle -string icnv
# Show full file extensions, the path bar, and the status bar
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# No .DS_Store litter on network shares and USB drives other OSes read
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- iTerm2 -------------------------------------------------------------------
# New windows use the chezmoi-managed profile (DynamicProfiles/dotfiles.json)
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string 5E0D7A3C-2B51-4C1E-9F3A-6D2B8C4E1A70
# Let nvim set the clipboard with OSC 52 - what makes copying work from
# inside an ssh session
defaults write com.googlecode.iterm2 AllowClipboardAccess -bool true

killall Finder Dock 2>/dev/null || true
