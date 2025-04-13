.PHONY: all
all: dnf oh-my-bash flatpak dotbot

.PHONY: dnf
dnf:
	sudo dnf install -y $(shell grep -vE "^\s*#" ./dnf.txt | tr "\n" " ")

.PHONY: flatpak
flatpak:
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	sudo flatpak install -y flathub $(shell grep -vE "^\s*#" ./flatpak.txt | tr "\n" " ")

.PHONY: oh-my-bash
oh-my-bash:
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended

.PHONY: dotbot
dotbot: dotbot-install dotbot-terminal

.PHONY: dotbot-install
dotbot:
	git submodule update --init --recursive

.PHONY: dotbot-terminal
dotbot-terminal:
	sh ./dotfiles/dotbot/bin/dotbot -c ./dotfiles/dotbot.conf.yaml

.PHONY: dotbot-kde
dotbot-kde:
	sh ./dotfiles/dotbot/bin/dotbot -c ./dotfiles/kde/dotbot-kde.conf.yaml

.PHONY: dotbot-gnome
dotbot-gnome:
	sh ./dotfiles/dotbot/bin/dotbot -c ./dotfiles/dotbot-gnome.conf.yaml

.PHONY: gitignore-global
gitignore-global:
	git config --global core.excludesfile $(shell pwd)/dotfiles/gitignore_global

.PHONY: zerotier
zerotier:
	curl -s https://install.zerotier.com | sudo bash

.PHONY: tailscale
tailscale:
	curl -fsSL https://tailscale.com/install.sh | sh

.PHONY: nvidia
nvidia:
	sudo dnf install -y akmod-nvidia
	sudo dnf install -y xorg-x11-drv-nvidia-cuda

.PHONY: dconf
dconf:
	dconf dump / > dconf-settings-backup.ini
