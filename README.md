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
| Windows | `.chezmoi.os == "windows"` | Chocolatey + packages, AutoHotkey hotkeys, Windows Terminal config, psmux, shared dotfiles (vim, git), Godot + editor settings (symlinked) |

(Godot and art/media apps additionally require the `gamedev` profile.)

## Shell and terminal

zsh + oh-my-zsh with the **agnoster** theme, except on the Steam Deck, which
keeps bash + oh-my-bash (pacman packages don't survive SteamOS updates).

Every interactive terminal `exec`s straight into **tmux**, themed with
[oh-my-tmux](https://github.com/gpakosz/.tmux) (cloned into `~/.tmux` by
`run_once_before_26`; `~/.tmux.conf` is a symlink into that clone, and our
overrides live in `dot_tmux.conf.local`). Each terminal starts its *own* session,
so two ddterm tabs are two independent sessions rather than two views of one, and
quitting tmux closes the terminal. The guards in `.zshrc` keep tmux out of
scripts, editor-embedded terminals, and bare TTYs.

The status bar deliberately matches the agnoster prompt: the same powerline
chevrons, and the same role → colour mapping (blue = where you are, green =
who you are, yellow = something wants you, grey = ambient chrome). Colours are
ANSI *names*, not hex, so tmux resolves them through the same terminal palette
agnoster's prompt does — the bar and the prompt can't drift apart.

Mouse mode is on (oh-my-tmux ships it off): without it the wheel never reaches
tmux and the terminal turns it into Up/Down arrows, which walks the shell's
history instead of scrolling. A mouse drag copies straight to the system
clipboard; **Shift + drag** bypasses tmux for the terminal's own selection.
Prefix-free keys: **Alt + h/j/k/l** between panes, **Alt + -** / **Alt + _** to
split, **Ctrl+Alt + h/l/n** for windows. Editing `.tmux.conf.local` only takes
effect when the tmux *server* restarts — press **prefix + r** to reload it into
a running one.

> **The terminals have to agree on two things**, or the bar renders differently
> on each machine — both are configured here, but they're easy to break:
>
> - **The same palette.** ANSI names resolve through each terminal's palette.
>   ptyxis's GNOME palette has separate light/dark variants and picks dark
>   automatically (blue = `#1e78e4`); ddterm has one static palette, and it
>   shipped the *light* values (`#12488b`), so the same ANSI slot was a different
>   colour in each. `dconf/ddterm.ini` now carries the GNOME **Dark** values.
> - **Bold must not be brightened.** oh-my-tmux emits the current window's
>   trailing chevron with no attribute reset, so it inherits the segment's bold.
>   A terminal that promotes bold ANSI 0–7 *foregrounds* to their bright variants
>   (backgrounds are never promoted) draws that chevron bright against a
>   normal-blue badge. ptyxis defaults this off; `dconf/ddterm.ini` sets
>   `bold-is-bright=false`; Windows Terminal's `settings.json` sets
>   `intenseTextStyle=bold`, because its default is `bright`.

> **Editing the status bar:** oh-my-tmux only treats ` , ` and ` | ` as
> separators at brace depth 0 — its `awk` deliberately protects commas inside
> `#{...}`. So a divider *inside* a `#{?...}` conditional (like the one between
> the battery and the clock) has to be a literal chevron, not a ` , `.
>
> Segments built from `#(...)` shell commands — battery status, username,
> hostname — only run when a **client is attached** and the bar actually
> redraws. In a detached session they render empty, which looks exactly like a
> broken config but isn't.

Native Windows has no tmux, so Chocolatey installs
[psmux](https://github.com/psmux/psmux) — a Rust tmux clone that speaks tmux
config and reads `~/.psmux.conf`. oh-my-tmux itself can't run there (it builds
its status bar by piping its own config back through `sh`/`sed`/`awk`/`perl`),
so `dot_psmux.conf` reproduces the same look by hand in plain tmux syntax. It's
a second copy of the theme on purpose — **keep the two in sync by eye**. Windows
machines running WSL Fedora get the real tmux + oh-my-tmux inside WSL.

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
.chezmoiscripts/windows/ Windows install scripts (Chocolatey, hotkey relaunch, default terminal)
dot_*                    the dotfiles themselves (dot_bashrc -> ~/.bashrc, ...)
dot_local/bin/           godot-update, czsave-dconf + optional install-* helpers
AppData/                 Windows-native dotfiles: Terminal settings, Startup hotkeys.ahk
docs/                    recipes, roadmap, recovered notes, backups
dconf/                   scoped GNOME settings dumps (loaded on desktop, saved via czsave-dconf)
```
