#!/bin/bash

cat > ~/.local/share/applications/godot.desktop << 'EOF'
[Desktop Entry]
Name=Godot Engine 4.6.3
Comment=2D and 3D cross-platform game engine
Exec=/opt/Godot_v4.6.3-stable_linux.x86_64 %f
Icon=Icon=/home/slug/.local/share/icons/godot.svg
Terminal=false
Type=Application
Categories=Development;IDE;Game;
Keywords=godot;game;engine;2d;3d;
MimeType=application/x-godot-project;
StartupWMClass=Godot
StartupNotify=true
EOF

# register it with the desktop
update-desktop-database ~/.local/share/applications/

# copy icon
cp ./resources/icon.svg ~/.local/share/icons/godot.svg
