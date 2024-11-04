sudo dnf install -y ruby ydotool
sudo gem install fusuma

cp ./config.yml ~/.config/fusuma/

# enable ydotool service, run with socket in home dir
sudo systemctl enable ydotool.service
sudo cp ./ydotool.service /usr/lib/systemd/system/ydotool.service
sudo systemctl daemon-reload
sudo systemctl start ydotool.service

# add user to input group to not need sudo
sudo gpasswd -a $USER input
newgrp input
