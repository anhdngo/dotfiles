# dotfiles

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/). One command sets up
any of my machines: shell aliases, terminal programs, Godot, and (on the desktop)
GNOME settings and GUI apps.

## Install

On a fresh OS (git recommended; chezmoi falls back to its builtin git if
missing), paste the line for the machine's [profile](#profiles).

**coding** — programming tools incl. Claude Code (work computer):

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo --promptChoice "Machine profile=coding"
```

**coding-noai** — same, without Claude Code / AI tooling:

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo --promptChoice "Machine profile=coding-noai"
```

**gamedev** — everything: coding + AI + Godot + art/media:

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo --promptChoice "Machine profile=gamedev"
```

That's it. This installs chezmoi to `~/.local/bin`, clones this repo to
`~/.local/share/chezmoi`, detects the machine type, writes all dotfiles, and
runs the install scripts. (Leave the `--promptChoice` flag off to be asked for
the profile interactively.) Re-running it (or `chezmoi update`) is always safe.

Then **open a new shell** (or `exec bash -l`) — `~/.local/bin` lands on PATH
via the just-applied dotfiles, so the shell that ran the one-liner won't see
`chezmoi` yet.

> **Note (first run on a machine with existing dotfiles):** review what would
> change with `chezmoi diff` first if you care about local edits — `apply`
> overwrites unmanaged changes.

### Windows

chezmoi runs natively on Windows — same repo, no WSL required. Like the Linux
one-liners, these work on a completely fresh install (nothing but PowerShell +
internet needed): chezmoi's install script fetches a throwaway `chezmoi.exe`
into `.\bin` and runs it; apply then installs Chocolatey and a permanent
`chezmoi` package, so day-2 commands work from any new shell. Paste the line
for the machine's profile:

**coding** — work computer (use `profile=coding-noai` for one without AI tooling):

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --apply anhdngo --promptChoice 'Machine profile=coding'"
```

**gamedev** — gamedev machine:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --apply anhdngo --promptChoice 'Machine profile=gamedev'"
```

Afterwards you can delete the leftover `.\bin\chezmoi.exe` — the one on PATH
comes from Chocolatey.

Apply installs the choco packages (the script self-elevates), puts the
AutoHotkey hotkeys in the Startup folder (and launches them), and writes the
Windows Terminal config (Ctrl+\ quake mode, CaskaydiaCove Nerd Font so
oh-my-zsh themes render correctly in WSL), and makes Windows Terminal the
default terminal application so the cmd/powershell hotkeys open in it instead
of the legacy conhost window. Shared dotfiles (`.vimrc`,
`.gitconfig`, `.config/git`) apply on Windows too; bash/GNOME files are
skipped automatically. On the gamedev profile the art/media choco packages
install too, plus the latest Godot + Godot .NET and the editor settings —
see [Godot](#godot) below.

`chezmoi init` also asks whether to install WSL with the latest Fedora
(preseed with `--promptBool "Install WSL with the latest Fedora=true"`); if
yes, apply installs the distro whenever it's missing. Start it once
(`wsl -d FedoraLinux-<N>`) to create your Linux user, then paste this inside
it — the WSL side is set up separately and gets the shell setup and
`~/winhome`:

```sh
sudo dnf install -y gawk tar git && cd ~ && sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo
```

This differs from the plain Linux one-liner because Fedora's WSL image is
minimal — it ships without `awk` (and friends), which chezmoi's install
script needs — and because WSL starts in the Windows directory you launched
it from, not `~`. It asks for the [profile](#profiles) interactively; append
a `--promptChoice` flag as above to preseed it.

### macOS

The plain Linux one-liners work as-is on a Mac (Apple Silicon): paste the line
for the machine's profile into Terminal. It asks for your password once, to
install Homebrew (which also installs the Xcode Command Line Tools if needed).

Apply installs the Homebrew formulae and casks from `packages.yaml` (apps
already in `/Applications` are adopted, not reinstalled), oh-my-zsh, and
then the same zsh/nvim/git setup Linux gets. On top of that come the Mac-only
pieces:

- **iTerm2 profiles** (`Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json`):
  `dotfiles` for normal windows (made the default) and `dotfiles hotkey`, a
  quake-style drop-down on **Cmd+\\** (ddterm's Ctrl+\\ on Linux). Both carry the
  GNOME dark palette, JetBrainsMono Nerd Font, bold-not-bright, and
  **Option as Esc+** — without that, Alt-chords (shell word movement, nvim)
  type `˙∆˚¬` instead. They also carry iTerm2's **Claude Code
  integration** triggers (open the Claude Code workgroup while `claude`
  runs) and hide the shell-integration prompt marks. Dynamic profiles are
  read-only to iTerm2: settings changed in its UI, or "installed" by iTerm2
  onto them, vanish on the next reload, so make lasting changes in the JSON.
  Delete any older hotkey-window profile you made by hand (Settings →
  Profiles), or the two fight over the key.
- **Global hotkeys** (`~/.hammerspoon/init.lua`, the `hotkeys.ahk` twin):
  Ctrl+Option+B / +Shift+B browser / private, Ctrl+Option+T terminal,
  Ctrl+Option+E Finder, Ctrl+Shift+Esc Activity Monitor, Ctrl+Option+Delete
  close window, **Caps Lock → Mission Control**, mouse back/forward → previous
  / next desktop. Caps Lock is remapped to F18 by a LaunchAgent so Hammerspoon
  can bind it.
- **System settings** (`run_onchange_after_40-defaults.sh`, the dconf
  counterpart): dark mode, key repeat instead of the accent popup, fixed
  desktop order, Finder opening in `~` with folders first and extensions shown.
- **Daily `chezmoi update`** via a LaunchAgent instead of the systemd timer
  (log: `~/Library/Logs/chezmoi-update.log`).
- On the gamedev profile, Godot + Godot .NET come from Homebrew casks
  (`brew upgrade` instead of `godot-update`), and
  `~/Library/Application Support/Godot` becomes a symlink into
  `~/.config/godot` like `%APPDATA%\Godot` on Windows. An existing real folder
  is moved to `Godot.bak` first, keeping everything chezmoi doesn't manage.

**One-time manual steps afterwards:** grant Hammerspoon *Accessibility*
access when it asks (System Settings → Privacy & Security), then restart
iTerm2 so it picks up the default profile. Dark mode and desktops spanning
all displays take effect after logging out and back in.

## Profiles

Besides OS detection, every machine picks a **profile** at `chezmoi init`
(stored in the local config, never committed):

| Profile | Gets |
|---|---|
| `coding` | programming tools + Claude Code with MCP servers — safe for a work computer |
| `coding-noai` | programming tools only, no Claude Code / AI tooling |
| `gamedev` | everything: coding + AI + Godot + art/media apps (GIMP, OBS, VLC, …) |

Every profile installs the GitHub (`gh`) and GitLab (`glab`) CLIs. On the AI
profiles a script installs Claude Code (native installer) and registers the
MCP servers listed in `.chezmoidata/claude.yaml` at user scope.

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
| Windows | `.chezmoi.os == "windows"` | Chocolatey + packages, AutoHotkey hotkeys, Windows Terminal config, shared dotfiles (vim, git), Godot + editor settings (symlinked) |
| macOS | `.chezmoi.os == "darwin"` | terminal setup, Homebrew formulae + casks, iTerm2 profiles, Hammerspoon hotkeys, macOS defaults, Godot casks + editor settings (symlinked) |

(Godot and art/media apps additionally require the `gamedev` profile.)

## Shell and terminal

zsh + oh-my-zsh with the **agnoster** theme, except on the Steam Deck, which
keeps bash + oh-my-bash (pacman packages don't survive SteamOS updates).

The prompt ends in a round cap (U+E0B4), a Nerd Font glyph: GUI Linux gets
JetBrainsMono Nerd Font (`run_once_before_15`), macOS the same font as a cask,
and Windows Terminal CaskaydiaCove Nerd Font. No terminal multiplexer: use the
terminal's own tabs and splits (ddterm, iTerm2, Windows Terminal).

> **Bold must not be brightened.** A terminal that promotes bold ANSI 0–7
> *foregrounds* to their bright variants (backgrounds are never promoted) draws
> bold powerline glyphs a lighter shade than their segment. ptyxis defaults
> this off; `dconf/ddterm.ini` sets `bold-is-bright=false`; Windows Terminal's
> `settings.json` sets `intenseTextStyle=bold`; the iTerm2 profiles turn off
> "Use Bright Bold". ddterm also carries the GNOME **Dark** palette values, so
> ANSI colours match ptyxis.

## Godot

`godot-update` (on PATH) installs or updates the latest stable Godot + Godot .NET
from the official builds into `~/.local/lib/godot`, keeping only the current
version. `godot` and `godotnet` are on PATH, and `$GODOT_PATH` /
`$GODOT_NET_PATH` point at stable symlinks that survive updates. It runs
automatically on first install; run it manually to update.

Windows has its own `godot-update` (`godot-update.ps1`, managed by chezmoi in
`%LOCALAPPDATA%\Programs\Godot\bin`) that mirrors the Linux script: latest
stable + .NET from the official builds, only the current version kept.
Instead of symlinks it rewrites stable entry points on each update: `godot` /
`godotnet` shims (the bin dir is added to the user PATH), Start Menu entries,
and `GODOT_PATH` / `GODOT_NET_PATH` user environment variables.

The editor settings (`editor_settings-*.tres`, `editor_layouts.cfg`) live in
`.config/godot/` in this repo — one copy for every OS. On Linux that's the
path Godot reads natively; on Windows chezmoi applies the same files to
`~\.config\godot` and creates `%APPDATA%\Godot` as a symlink pointing there,
so the editor reads and writes through it and `chezmoi re-add` picks up
changes identically on both OSes.

> **Windows notes:** creating the symlink needs Developer Mode enabled (or an
> elevated `chezmoi apply`). If a real `%APPDATA%\Godot` directory already
> exists, chezmoi won't replace it with a symlink — move it aside first
> (`Rename-Item $env:APPDATA\Godot Godot.bak`), apply, then copy anything you
> want to keep (e.g. `app_userdata`, `export_templates`) back into the new
> location.

## Day-2 commands

| Task | Command |
|---|---|
| pull latest dotfiles + apply | `chezmoi update` (also runs daily via `chezmoi-update.timer`, or a LaunchAgent on macOS) |
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
.chezmoidata/packages.yaml   all package lists (dnf/apt/flatpak/choco/brew/extensions)
.chezmoidata/dconf.yaml  which dconf paths are saved/loaded
.chezmoiscripts/linux/   Linux install scripts, run by `chezmoi apply` in order
.chezmoiscripts/windows/ Windows install scripts (Chocolatey, hotkey relaunch, default terminal)
.chezmoiscripts/darwin/  macOS install scripts (Homebrew, defaults, LaunchAgents, Firefox policies)
dot_*                    the dotfiles themselves (dot_bashrc -> ~/.bashrc, ...)
dot_local/bin/           godot-update, czsave-dconf + optional install-* helpers
AppData/                 Windows-native dotfiles: Terminal settings, Startup hotkeys.ahk
Library/                 macOS-native dotfiles: iTerm2 profiles, LaunchAgents, Godot symlink
dot_hammerspoon/         macOS global hotkeys (~/.hammerspoon/init.lua)
docs/                    recipes, roadmap, recovered notes, backups
dconf/                   scoped GNOME settings dumps (loaded on desktop, saved via czsave-dconf)
```
