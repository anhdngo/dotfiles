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
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

.PHONY: dotbot
dotbot:
	git submodule update --init --recursive
	sh ./dotfiles/dotbot/bin/dotbot -c ./dotfiles/dotbot.conf.yaml

.PHONY: gitignore-global
gitignore-global:
	git config --global core.excludesfile $(shell pwd)/dotfiles/gitignore_global

.PHONY: zerotier
zerotier:
	curl -s https://install.zerotier.com | sudo bash
