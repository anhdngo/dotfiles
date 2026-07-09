# dotfiles

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/). One command sets up
any of my machines: shell aliases, terminal programs, Godot, and (on the desktop)
GNOME settings and GUI apps.

## Install

On a fresh OS (git recommended; chezmoi falls back to its builtin git if missing):

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo
```

That's it. This installs chezmoi to `~/.local/bin`, clones this repo to
`~/.local/share/chezmoi`, detects the machine type, writes all dotfiles, and runs
the install scripts. Re-running it (or `chezmoi update`) is always safe.

> **Note (first run on a machine with existing dotfiles):** review what would
> change with `chezmoi diff` first if you care about local edits — `apply`
> overwrites unmanaged changes.

### Windows

Windows needs both halves — run each in the right place:

| Where | Command | What it does |
|---|---|---|
| **WSL (bash)** | the one-liner above | shell, aliases, packages, `~/winhome` link |
| **Windows (PowerShell)** | `windows-setup` (alias, from WSL) — or run `windows\setup.ps1` in PowerShell | Chocolatey + packages, AutoHotkey hotkeys, Ctrl+\ quake terminal |

`setup.ps1` self-elevates; re-run it after editing `windows/choco-packages.txt`
or `windows/hotkeys.ahk`.

## What each machine gets

| Machine | Detected by | Gets |
|---|---|---|
| Fedora + GNOME | `ID=fedora`, not WSL | everything: dnf + flatpak apps, GNOME settings (dconf), shell extensions, input-remapper, Firefox policies, Godot, desktop entries |
| Fedora on WSL | kernel contains `microsoft` | terminal setup, dnf packages, Godot, `~/winhome` |
| Steam Deck | `ID=steamos` | terminal setup, user-scope flatpaks (never pacman — SteamOS updates wipe it), Godot |
| Debian server | `ID=debian` | terminal setup, apt packages (no GUI, no Godot) |

## Godot

`godot-update` (on PATH) installs or updates the latest stable Godot + Godot .NET
from the official builds into `~/.local/lib/godot`, keeping only the current
version. `godot` and `godotnet` are on PATH, and `$GODOT_PATH` /
`$GODOT_NET_PATH` point at stable symlinks that survive updates. It runs
automatically on first install; run it manually to update.

## Day-2 commands

| Task | Command |
|---|---|
| pull latest dotfiles + apply | `chezmoi update` (also runs daily via `chezmoi-update.timer`) |
| apply local changes | `chezmoi apply` |
| cd into this repo | `czd` (alias for `chezmoi cd`) |
| see what would change | `chezmoi diff` |
| start managing a new file | `chezmoi add ~/.config/foo/bar` |
| save current GNOME settings | `czsave-dconf` (then commit) |
| update Godot | `godot-update` |
| unlock Bitwarden for this shell | `bwu` |
| add an encrypted secret | `chezmoi add --encrypt <file>` (see docs/adding-things.md) |
| optional extras | `install-tailscale`, `install-zerotier`, `install-nvidia` |

> **New machine with secrets:** after the one-liner, run `bw login`, `bwu`,
> `install-age-key`, then `chezmoi apply` — encrypted files can't decrypt
> until the age key (stored in Bitwarden) is in place.

See [docs/adding-things.md](docs/adding-things.md) for recipes (add an alias, a
package, a machine type, …), [docs/future-improvements.md](docs/future-improvements.md)
for the roadmap, and [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md)
for the design of the chezmoi migration.

## Layout

```
.chezmoi.toml.tmpl       machine detection (gui / wsl / steamdeck / headless)
.chezmoidata/packages.yaml   all package lists (dnf/apt/flatpak/extensions)
.chezmoidata/dconf.yaml  which dconf paths are saved/loaded
.chezmoiscripts/         install scripts, run by `chezmoi apply` in order
dot_*                    the dotfiles themselves (dot_bashrc -> ~/.bashrc, ...)
dot_local/bin/           godot-update, czsave-dconf + optional install-* helpers
windows/                 Windows-native: setup.ps1, choco list, AutoHotkey
docs/                    recipes, roadmap, recovered notes, backups
dconf/                   scoped GNOME settings dumps (loaded on desktop, saved via czsave-dconf)
```
