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
`~/.local/share/chezmoi`, detects the machine type, asks for the profile,
writes all dotfiles, and runs the install scripts. Re-running it (or
`chezmoi update`) is always safe.

Then **open a new shell** (or `exec bash -l`) — `~/.local/bin` lands on PATH
via the just-applied dotfiles, so the shell that ran the one-liner won't see
`chezmoi` yet.

> **Note (first run on a machine with existing dotfiles):** review what would
> change with `chezmoi diff` first if you care about local edits — `apply`
> overwrites unmanaged changes.

### Windows

chezmoi runs natively on Windows — same repo, no WSL required. In PowerShell:

```powershell
winget install twpayne.chezmoi
chezmoi init --apply anhdngo
```

This installs Chocolatey + packages (the script self-elevates), puts the
AutoHotkey hotkeys in the Startup folder (and launches them), and writes the
Windows Terminal config (Ctrl+\ quake mode). Shared dotfiles (`.vimrc`,
`.gitconfig`, `.config/git`) apply on Windows too; bash/GNOME/Godot files are
skipped automatically. WSL on the same machine is set up separately with the
Linux one-liner above (it gets the shell setup and `~/winhome`).

## Profiles

Besides OS detection, every machine picks a **profile** at `chezmoi init`
(stored in the local config, never committed):

| Profile | Gets |
|---|---|
| `coding` | programming tools only — safe for a work computer |
| `gamedev` | everything: coding + Godot + art/media apps (GIMP, OBS, VLC, …) |

The prompt only fires once; to change an existing machine, edit `profile` under
`[data]` in `~/.config/chezmoi/chezmoi.toml`, then `chezmoi apply`. New
profiles: add a choice in `.chezmoi.toml.tmpl` and gate lists/files on it.

## What each machine gets

| Machine | Detected by | Gets |
|---|---|---|
| Fedora + GNOME | `ID=fedora`, not WSL | everything: dnf + flatpak apps, GNOME settings (dconf), shell extensions, input-remapper, Firefox policies, Godot, desktop entries |
| Fedora on WSL | kernel contains `microsoft` | terminal setup, dnf packages, `~/winhome` (headless — no Godot) |
| Steam Deck | `ID=steamos` | terminal setup, user-scope flatpaks (never pacman — SteamOS updates wipe it), Godot |
| Debian server | `ID=debian` | terminal setup, apt packages (no GUI, no Godot) |
| Windows | `.chezmoi.os == "windows"` | Chocolatey + packages, AutoHotkey hotkeys, Windows Terminal config, shared dotfiles (vim, git) |

(Godot and art/media apps additionally require the `gamedev` profile.)

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
.chezmoi.toml.tmpl       machine detection (windows / gui / wsl / steamdeck / headless) + profile prompt
.chezmoidata/packages.yaml   all package lists (dnf/apt/flatpak/choco/extensions)
.chezmoidata/dconf.yaml  which dconf paths are saved/loaded
.chezmoiscripts/linux/   Linux install scripts, run by `chezmoi apply` in order
.chezmoiscripts/windows/ Windows install scripts (Chocolatey, hotkey relaunch)
dot_*                    the dotfiles themselves (dot_bashrc -> ~/.bashrc, ...)
dot_local/bin/           godot-update, czsave-dconf + optional install-* helpers
AppData/                 Windows-native dotfiles: Terminal settings, Startup hotkeys.ahk
docs/                    recipes, roadmap, recovered notes, backups
dconf/                   scoped GNOME settings dumps (loaded on desktop, saved via czsave-dconf)
```
