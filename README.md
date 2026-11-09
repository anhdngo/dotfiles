# dotfiles

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/), for Fedora
(GNOME and WSL), macOS, Windows, a Debian server and the Steam Deck.

## Install

It asks for the machine's [profile](#profiles), then installs packages and
writes every dotfile.

**Linux / macOS:**

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo
```

**Windows** (PowerShell):

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -BinDir $env:TEMP -- init --apply anhdngo"
```

**Fedora in WSL** (if you answered yes to WSL on Windows): start it once with
`wsl -d FedoraLinux-<N>` to create your user, then run this inside it:

```sh
sudo dnf install -y gawk tar git && cd ~ && sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo
```

### Profiles

| Profile | Gets |
|---|---|
| `coding` | programming tools + Claude Code (fine for a work computer) |
| `coding-noai` | programming tools only |
| `gamedev` | everything: coding + Claude Code + Godot + art/media apps |

## After install

- **Everywhere:** open a new shell so `chezmoi` is on PATH.
- **GNOME:** log out and back in so the shell extensions load.
- **macOS:** open Hammerspoon and grant it Accessibility access, restart
  iTerm2, and approve the Firefox profile in System Settings > General >
  Device Management.

## Everyday commands

| Task | Command |
|---|---|
| pull the latest and apply | `chezmoi update` (Linux also does this daily) |
| apply edits made in the repo | `chezmoi apply` |
| preview what apply would change | `chezmoi diff` |
| save changes made in an app's UI back to the repo | `chezmoi re-add` |
| go to the repo | `czd` |

Then commit and push from the repo. Recipes for adding packages, secrets and
so on are in [docs/adding-things.md](docs/adding-things.md).

## Where things live

| To change | Edit |
|---|---|
| packages (every OS) | `.chezmoidata/packages.yaml` |
| Claude Code MCP servers | `.chezmoidata/claude.yaml` |
| aliases, env vars | `dot_aliases.tmpl` |
| shell | `dot_zshrc`, `dot_bashrc.tmpl`, `dot_zprofile` |
| nvim | `dot_config/nvim/init.lua` |
| GNOME settings | change them in the UI, then `czsave-dconf` (saves into `dconf/`) |
| macOS hotkeys, Caps Lock | `dot_hammerspoon/init.lua` |
| iTerm2 profiles | `Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json` |
| macOS settings for new Macs | `.chezmoiscripts/darwin/run_once_after_40-defaults.sh` |
| Locked Firefox extensions (Linux, macOS) | `firefox-policies.json` |
| Windows hotkeys | `AppData/…/Startup/hotkeys.ahk` |
| Windows Terminal | change it in the UI, then `chezmoi re-add` |
| Godot editor settings (all OSes) | `dot_config/godot/` |
| machine detection, profile prompt | `.chezmoi.toml.tmpl` |
| which files go on which machine | `.chezmoiignore` |
| install scripts | `.chezmoiscripts/<os>/` (run by `chezmoi apply`, in name order) |

## Gotchas

- **Changing a machine's profile:** edit `profile` in
  `~/.config/chezmoi/chezmoi.toml`, then `chezmoi apply`. `chezmoi init` won't
  ask again.
- **Godot:** `godot-update` installs and updates it on Linux and Windows;
  macOS uses Homebrew. The editor settings folder is a symlink to
  `~/.config/godot`. If Godot ran before chezmoi, move its settings folder
  (`~/Library/Application Support/Godot`, `%APPDATA%\Godot`) aside first. On
  Windows the symlink needs Developer Mode.
- **iTerm2** profiles can't be changed in its UI; edit the JSON.
- **macOS key remaps** (Caps Lock as a hyper key, Globe/fn ↔ Control) live
  in `dot_hammerspoon/init.lua`. Don't use System Settings → Keyboard →
  Modifier Keys: it and Hammerspoon overwrite each other.
- **The Linux daily update** can't use sudo, so after a package list change
  it fails until you run `chezmoi apply` yourself.
