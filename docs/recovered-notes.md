# Recovered notes (from the pre-chezmoi README)

Fixes and references that aren't applied by any script but are worth keeping.

## Wake from sleep is slow (Fedora)

On kernel 6.11.5-300, waking up from sleep takes 40+ seconds. Running
`journalctl -b` reveals the error `[drm] *ERROR* Failed to read DPCD register 0x92`.

To fix, edit `/etc/default/grub` to include the line:

```
GRUB_CMDLINE_LINUX_DEFAULT="intel_idle.max_cstate=4"
```

Then update grub:

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

## ydotool.service (KDE-era touchpad gestures)

Ydotool and fusuma were used to enable touchpad gesture configuration, since
Plasma 6 had not supported that yet. Fusuma triggers a ydotool command when a
gesture is triggered. After running the setup, add fusuma.sh to autostart.

Make sure to replace ydotool.service's `--socket-own` with the current user's
id and group (`id -u` / `id -g`). The full line was originally:

```
ExecStart=/usr/bin/ydotoold --socket-path="$HOME/.ydotool_socket" --socket-own="$(id -u):$(id -g)"
```

(The KDE configs themselves were dropped in the chezmoi migration; they live in
the `legacy` branch.)

## LeechBlock

`LeechBlockOptions.txt` in this directory is a backup of the LeechBlock NG
browser extension settings (exported 2025-05). To restore: LeechBlock NG
options → Import/Export tab → paste the file contents → Import.

## Ledger udev rules

The old `scripts/ledger_udev_rules.sh` (Ledger hardware wallet udev setup) was
dropped; if ever needed it's on the `legacy` branch, or use the upstream one:
`wget -q -O - https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh | sudo bash`
