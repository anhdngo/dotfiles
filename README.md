# dotfiles

## Install
```make```

# Fixes to Common Issues
## Wake From Sleep is Slow
On kernel 6.11.5-300, waking up from sleep takes 40+ seconds. Running `journalctl -b` reveals the error `[drm] *ERROR* Failed to read DPCD register 0x92`.  

To fix, edit the `/etc/default/grub` file to include the line:  
```GRUB_CMDLINE_LINUX_DEFAULT="intel_idle.max_cstate=4"```  
Then, update grub.
