#!/bin/bash

# install flatpaks
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub $(shell grep -vE "^\s*#" ./flatpak.txt | tr "\n" " ")

# install dotbot
submodule update --init --recursive
sh ./dotfiles/dotbot/bin/dotbot -c ./dotfiles/dotbot.conf.yaml




