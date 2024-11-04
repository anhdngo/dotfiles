# dotfiles

## Install
```make```

# Fixes to Common Issues
## Wake From Sleep is Slow
On kernel 6.11.5-300, waking up from sleep takes 40+ seconds. Running `journalctl -b` reveals the error `[drm] *ERROR* Failed to read DPCD register 0x92`.  

To fix, edit the `/etc/default/grub` file to include the line:  
```GRUB_CMDLINE_LINUX_DEFAULT="intel_idle.max_cstate=4"```  
Then, update grub.
```grub2-mkconfig -o /boot/grub2/grub.cfg```

## ydotool.service
Ydotool and fusuma are used to enable touchpad gesture configuration, since Plasma 6 has not supported that yet. Fusuma triggers ydotool command when gesture is triggered. After running the setup, add fusuma.sh to autostart.  

Make sure to replace ydotool.service's --socket-own with the current user's id and group which can be found with `id -u` and `id -g`. The full line was originally:
```ExecStart=/usr/bin/ydotoold --socket-path="$HOME/.ydotool_socket" --socket-own="$(id -u):$(id -g)"```
