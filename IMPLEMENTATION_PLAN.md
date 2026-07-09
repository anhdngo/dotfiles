# Chezmoi Migration — Implementation Plan

Migrate this dotbot/Makefile-based repo to [chezmoi](https://www.chezmoi.io/), hosted on
GitHub, installable on any of my machines with a single command, with per-OS behavior
handled by chezmoi templates instead of hand-picked Makefile targets.

## Decisions already made

| Decision | Choice |
|---|---|
| Repo location on disk | `~/.local/share/chezmoi` (chezmoi default). `~/.dotfiles` is retired; `dff` alias removed — use `chezmoi cd` instead. |
| KDE configs | Dropped entirely (stale Plasma-5 era; Steam Deck gets terminal-only setup). |
| Shell | Keep bash + oh-my-bash (agnoster theme), installed by script on every machine. |
| Windows | Two-part setup: chezmoi runs **inside WSL** as usual; a separate `windows/setup.ps1` (run in **admin PowerShell on Windows**) installs Chocolatey + packages, AutoHotkey hotkeys (absorbed from `~/Workspace/hotkeys`), and the Ctrl+\ quake-terminal hotkey. |
| Godot | Downloaded binaries only — drop the `org.godotengine.Godot` flatpak. `godot` and `godotnet` on PATH, `$GODOT_PATH` / `$GODOT_NET_PATH` set. |
| WSL | Windows home linked at `~/winhome`. |

**Why `~/.local/share/chezmoi` is the right location:** chezmoi's tooling
(`chezmoi cd`, `chezmoi edit`, `chezmoi add`) assumes it, the bootstrap one-liner clones
straight into it with zero configuration, and keeping `~/.dotfiles` would require a
sourceDir override on every new machine — friction that works against the
"one command, minimal setup" goal.

## Target machines

| Machine | Detection | Packages | GUI apps | GNOME settings | winhome |
|---|---|---|---|---|---|
| Fedora + GNOME (desktop) | `ID=fedora`, not WSL | dnf + flatpak | ✔ flatpak | ✔ dconf, extensions, input-remapper, bookmarks | — |
| Fedora on WSL | `ID=fedora` + `/proc/version` contains `microsoft` (or `$WSL_DISTRO_NAME`) | dnf | — | — | ✔ |
| Steam Deck | `ID=steamos` | flatpak + static binaries in `~/.local/bin` (pacman is wiped by SteamOS updates — avoid) | — | — | — |
| Debian headless server | `ID=debian` | apt | — | — | — |

Detection lives in `.chezmoi.toml.tmpl`, which computes booleans once at `chezmoi init`
and exposes them to every template and script:

```toml
{{ "{{" }}- $osid := .chezmoi.osRelease.id -{{ "}}" }}
{{ "{{" }}- $wsl := or (env "WSL_DISTRO_NAME" | not | not) (contains "microsoft" (output "cat" "/proc/version" | lower)) -{{ "}}" }}
[data]
    wsl = {{ "{{" }} $wsl {{ "}}" }}
    steamdeck = {{ "{{" }} eq $osid "steamos" {{ "}}" }}
    headless = {{ "{{" }} eq $osid "debian" {{ "}}" }}
    gui = {{ "{{" }} and (eq $osid "fedora") (not $wsl) {{ "}}" }}
```

(If detection ever guesses wrong, a `promptBoolOnce` fallback can ask on first init.)

## One-command install

On a fresh OS, after installing git (and nothing else):

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply anhdngo
```

**The GitHub repo keeps the name `dotfiles`** (`github.com/anhdngo/dotfiles`): chezmoi's
`init <github-username>` shorthand specifically looks for a repo with that name, which is
what keeps the one-liner this short. Any other name would work but the command becomes
`init --apply anhdngo/<name>`.

Where everything lands after that one command:

| What | Where |
|---|---|
| chezmoi binary | `~/.local/bin/chezmoi` (the `/lb` suffix selects `~/.local/bin`; plain `get.chezmoi.io` would use `./bin`) |
| the cloned repo ("source state") | `~/.local/share/chezmoi` (a normal git repo — commit/push from there) |
| generated machine config | `~/.config/chezmoi/chezmoi.toml` (rendered once from `.chezmoi.toml.tmpl`) |
| the actual dotfiles | `$HOME` (rendered copies, not symlinks — chezmoi diffs/updates them on `apply`) |

It then runs the install scripts below in order. Re-running it (or `chezmoi update`)
is always safe/idempotent.

## Target repo layout

```
~/.local/share/chezmoi/
├── README.md
├── .chezmoi.toml.tmpl              # machine detection (above)
├── .chezmoiignore                  # per-machine exclusions (GNOME files ignored unless gui)
├── .chezmoidata/
│   └── packages.yaml               # dnf/apt/flatpak package lists (single source of truth)
│
│  # dotfiles (applied on every machine)
├── dot_local/bin/executable_godot-update   # standalone Godot install/update command (§4)
├── dot_local/bin/executable_install-tailscale   # optional, run on demand (was Makefile target)
├── dot_local/bin/executable_install-zerotier    # optional, run on demand (was Makefile target)
├── dot_local/bin/executable_install-nvidia      # optional, NVIDIA machines only (was Makefile target)
├── dot_bashrc
├── dot_profile.tmpl                # PATH, env vars; guards optional sources
├── dot_aliases.tmpl                # aliases + env vars; winhome/GUI bits templated
├── dot_vimrc
├── dot_gitconfig
├── dot_config/
│   ├── nvim/init.lua
│   ├── git/ignore                  # replaces gitignore_global (no gitconfig pointer needed)
│   └── godot/                      # editor settings, native path (was flatpak ~/.var path)
│
│  # GNOME-only (listed in .chezmoiignore unless .gui)
├── dot_config/input-remapper-2/...
├── dot_config/gtk-3.0/bookmarks
├── dot_local/share/applications/*.desktop.tmpl   # godot.desktop Exec uses template
├── dot_local/share/icons/...
│
│  # WSL-only
├── symlink_winhome.tmpl            # → /mnt/c/Users/<user> (WSL only, via .chezmoiignore)
│
│  # Windows-native (NOT applied by chezmoi — run manually from Windows, see §7)
├── windows/
│   ├── setup.ps1                   # run in admin PowerShell ON WINDOWS (not WSL)
│   ├── choco-packages.txt          # chocolatey package list
│   ├── hotkeys.ahk                 # AutoHotkey v2 hotkeys (from ~/Workspace/hotkeys)
│   └── terminal-settings.json      # Windows Terminal config incl. Ctrl+\ quake hotkey
│
│  # scripts, run automatically by `chezmoi apply` in filename order
├── .chezmoiscripts/
│   ├── run_onchange_before_10-packages.sh.tmpl    # dnf / apt / flatpak from packages.yaml
│   ├── run_once_before_20-oh-my-bash.sh
│   ├── run_onchange_after_30-godot.sh.tmpl        # skipped on headless
│   ├── run_onchange_after_40-dconf.sh.tmpl        # gui only
│   ├── run_once_after_50-gnome-extras.sh.tmpl     # gui only: extensions, firefox policies, input-remapper service
│   └── run_once_after_60-wsl.sh.tmpl              # wsl only (fallback if symlink template insufficient)
│
└── docs/
    ├── adding-things.md            # how to add aliases, packages, dotfiles, machines
    ├── recovered-notes.md          # the grub/ydotool notes from the old README
    └── LeechBlockOptions.txt       # manual-import backup + how to re-import it
```

Naming conventions used above (chezmoi's, worth knowing):

- `dot_foo` → `~/.foo`; `symlink_foo` → symlink at `~/foo`; `.tmpl` suffix → rendered with machine data.
- `run_once_*` runs one time per machine; `run_onchange_*` re-runs whenever its rendered content changes — so scripts embed a hash of their data (package lists, dconf.ini) and automatically re-run when those change.
- `.chezmoiignore` is itself a template, so GNOME files are simply not applied on non-GUI machines:

```
{{ "{{" }} if not .gui {{ "}}" }}
.config/input-remapper-2
.config/gtk-3.0
.local/share/applications
.local/share/icons
{{ "{{" }} end {{ "}}" }}
{{ "{{" }} if not .wsl {{ "}}" }}
winhome
{{ "{{" }} end {{ "}}" }}
windows        # Windows-native files; never applied to a Linux home dir
```

## Detailed work items

### 1. Bootstrap the chezmoi source repo

- `chezmoi init` locally, port files one at a time with `chezmoi add <file>`
  (chezmoi reads the *target* file, so the current dotbot symlinks must be replaced by
  real files as part of this — see migration checklist).
- Point the repo at the existing GitHub remote (`anhdngo/dotfiles`), migrating on a
  branch (`chezmoi-migration`) so the old master stays intact until every machine is
  converted. Merge to master when done.
- Remove the dotbot submodule, Makefile, and all dotbot YAML.

### 2. Shell: bashrc / profile / aliases

- `dot_bashrc`: current file minus the two machine-specific absolute paths
  (`OSH` becomes `$HOME/.oh-my-bash`, drop the hardcoded Antigravity PATH line —
  PATH handling moves to profile).
- `dot_profile.tmpl`: PATH (`~/bin`, `~/.local/bin`), `EDITOR`, and guard the
  `. "$HOME/.local/bin/env"` line with a file-existence check (it's the uv installer
  script; it doesn't exist on fresh machines).
- `dot_aliases.tmpl` keeps all navigation aliases and env vars: `ws`, `gws`, `as`,
  `cf`, `dt`, `dl`, `doc`, plus tool aliases (`vi`/`vim`→nvim, `g`, `ll`, `rl`, …).
  Changes:
  - **Remove** `dff` and `$DOTFILES` (use `chezmoi cd`); add `cz="chezmoi"` and
    `czd="chezmoi cd"` for convenience.
  - Fix directory aliases so they actually `cd` (today `alias ws="~/Workspace"` tries to
    *execute* the directory). Standardize on `alias ws='cd $WS'` style — this is also the
    documented pattern for adding new ones.
  - GUI-only aliases (`e`/`f`→nautilus, steam/gdata paths) wrapped in
    `{{ "{{" }} if .gui {{ "}}" }}`; the old flatpak-Godot `gdata` path updated or dropped.
  - `GODOT_PATH` / `GODOT_NET_PATH` exported here (see §4), skipped on headless.
- Adding a new alias/env var forever after = edit one file, `chezmoi apply`, commit.

### 3. Packages

- `.chezmoidata/packages.yaml` with keys: `dnf`, `apt`, `flatpak_gui`, `flatpak_deck`.
  Current `dnf.txt` splits into cross-machine terminal tools (gcc, make, git, ripgrep,
  fd-find, unzip, neovim, p7zip, fastfetch, powerline-fonts, mercurial) and GNOME-only
  (gnome-tweaks, input-remapper, seahorse, extension packages). `flatpak.txt` carries
  over minus `org.godotengine.Godot`.
- `run_onchange_before_10-packages.sh.tmpl` embeds the rendered lists (so any edit to
  packages.yaml triggers a re-run) and branches on machine type:
  - Fedora (both): `sudo dnf install -y …`
  - Debian: `sudo apt-get install -y …` (map name differences: `fd-find`→`fd-find`,
    `p7zip`→`7zip`, etc. — the yaml keeps per-manager lists precisely so no runtime
    name-mapping logic is needed)
  - GUI: add flathub remote + `flatpak install -y` the GUI list
  - Steam Deck: flatpak only (user scope, no sudo); neovim etc. via flatpak or static
    binaries into `~/.local/bin` — **never pacman** (wiped on SteamOS updates)
- Debian headless gets *no* flatpak; WSL gets *no* flatpak.

### 4. Godot installer + updater

Replaces `godot-shortcut.sh` and the `/opt/Godot_v4.7…` hardcoding. Applies to all
machines except the headless server (templated out).

The download/update logic lives in a standalone, rerunnable command —
`dot_local/bin/executable_godot-update` in the source tree, installed to
`~/.local/bin/godot-update` — so updating later is just typing `godot-update`.
The chezmoi script `run_onchange_after_30-godot.sh.tmpl` only calls it during
`chezmoi apply` so fresh installs get Godot automatically. What it does:

- Query the latest stable release from the official GitHub builds repo
  (`api.github.com/repos/godotengine/godot-builds/releases/latest` — this is what the
  website links to), pick the `linux.x86_64` and `mono_linux_x86_64` assets.
- Download + unzip into versioned dirs under `~/.local/lib/godot/` (user-writable —
  works on Steam Deck's read-only rootfs, no sudo needed; `/opt` is retired).
  `~/.local/lib/<name>` is the standard user-level home for self-contained app
  payloads (the per-user analog of `/usr/lib`, per systemd file-hierarchy(7)), with
  only launchers/symlinks going in `~/.local/bin`. Note `~/.local/share/godot` is
  deliberately avoided — the Godot editor already uses it for its own data.
- Maintain stable symlinks, refreshed atomically on each update:
  - `~/.local/lib/godot/godot` → versioned standard executable
  - `~/.local/lib/godot/godotnet` → versioned .NET executable
  - `~/.local/bin/godot` and `~/.local/bin/godotnet` → the above
- **Symlinks in `~/.local/bin`, not aliases** — that's the standard choice: they work
  from GUI launchers, `.desktop` files, scripts, and non-interactive shells; aliases
  only exist in interactive bash.
- `dot_aliases.tmpl` exports `GODOT_PATH="$HOME/.local/lib/godot/godot"` and
  `GODOT_NET_PATH="$HOME/.local/lib/godot/godotnet"` — stable paths that survive
  version bumps because the script only retargets the symlinks.
- Skip the download if the installed version already matches latest (idempotent);
  when a newer version exists, download it, retarget the symlinks, then **delete the
  previous version's directory** — the old binary is overridden, only the current
  version is kept on disk. A `--force` flag re-downloads even when up to date
  (repair a broken install).
- GUI machines: `godot.desktop` becomes a chezmoi template pointing `Exec=` at
  `$HOME/.local/lib/godot/godot`, icon installed from the repo (replaces both
  `godot-shortcut.sh` and `install-desktop-files.sh`; `renpy.desktop` ported the same way).
- Godot editor settings move from the flatpak path (`~/.var/app/org.godotengine.Godot/…`)
  to the native `~/.config/godot/`.
- Note in docs: the .NET build needs the dotnet SDK to export/build C# — add
  `dotnet-sdk-8.0` to the dnf list (GUI machine) or document as manual.

### 5. GNOME (gui only)

- `run_onchange_after_40-dconf.sh.tmpl`: `dconf load / < dconf.ini`, with the hash of
  `dconf.ini` embedded so it re-applies only when the dump changes. `dconf.ini` lives in
  the repo root (chezmoi ignores it as a target via `.chezmoiignore`).
  Add a helper for the reverse direction: `czsave-dconf` alias →
  `dconf dump / > "$(chezmoi source-path)/dconf.ini"` then commit.
- `run_once_after_50-gnome-extras.sh.tmpl`:
  - GNOME shell extensions: install non-interactively with
    [`gnome-extensions-cli` (pipx)](https://pypi.org/project/gnome-extensions-cli/) from
    the current URL list (ddterm, hot-edge, tiling-shell), replacing the
    xdg-open-a-browser-tab approach. Fallback documented: open URLs manually.
  - Firefox policies: `sudo install -D firefox-policies.json /etc/firefox/policies/policies.json`.
  - `sudo systemctl enable input-remapper` (configs themselves are plain chezmoi-managed
    files under `dot_config/input-remapper-2/`).
- gtk bookmarks + input-remapper presets become normal managed files (no script needed).

### 6. WSL (`symlink_winhome.tmpl` / `run_once_after_60-wsl.sh.tmpl`)

- `~/winhome` → the Windows user profile. Resolve the target at apply time:
  `wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')"` with a fallback
  to globbing `/mnt/c/Users/`. If the resolved path is clean, a `symlink_winhome.tmpl`
  one-liner is enough; otherwise the run_once script creates it. Ignored on non-WSL
  machines via `.chezmoiignore`.

### 7. Windows native setup (`windows/` — run ON WINDOWS, not in WSL)

Two clearly separated scripts on a Windows machine, documented side by side in the README:

| Where | What to run | What it does |
|---|---|---|
| **WSL (bash)** | the chezmoi one-liner | everything in this plan: shell, aliases, packages, `~/winhome` |
| **Windows (admin PowerShell)** | `windows\setup.ps1` | Chocolatey, choco packages, AutoHotkey hotkeys, terminal hotkey |

Since the repo lives inside WSL, the Windows script is reachable from Windows at
`\\wsl.localhost\<distro>\home\slug\.local\share\chezmoi\windows\setup.ps1`. For
convenience, WSL machines get a `windows-setup` alias that launches it in an elevated
PowerShell from inside WSL, so in practice both halves can be run from the same WSL
terminal.

`windows/setup.ps1` (idempotent, safe to re-run):

1. **Install Chocolatey** if `choco` isn't on PATH (official install snippet).
2. **Install the choco package list** from `windows/choco-packages.txt` —
   one package per line, `#` comments, same convention as the Linux lists.
   Seeded with `autohotkey` (v2) and the current Windows staples; adding a program
   later = add a line, re-run the script.
3. **AutoHotkey hotkeys** (absorbs the `~/Workspace/hotkeys` repo — `hotkeys.ahk`
   moves into `windows/`, that repo gets archived):
   - Copy `hotkeys.ahk` to `%LOCALAPPDATA%\hotkeys\` and create a Startup-folder
     shortcut to the copy. Copy rather than link: `\\wsl.localhost` isn't mounted
     until WSL starts, so a shortcut into the repo would silently fail at login.
     Re-running setup.ps1 refreshes the copy after edits.
   - Launch it immediately so hotkeys work without relogging.
4. **Quake terminal on Ctrl+\\**: apply `windows/terminal-settings.json` to Windows
   Terminal's `LocalState\settings.json` (backing up the existing file), containing a
   global-summon/quake-mode keybinding on `ctrl+\`. This is done in Windows Terminal
   itself rather than AutoHotkey because WT's global hotkey properly *toggles* the
   quake window (show/hide/focus); an AHK `Run("wt -w _quake")` can only show it.
   The old `^!Enter` cmd/wsl hotkey in hotkeys.ahk stays (or can be retired later —
   quake WSL profile covers it).

### 8. Cleanups found during audit (fix as part of the port)

- `dotfiles/gitconfig` points `core.excludesfile` at `~/.linux-configs/dotfiles/gitignore_global`
  — a path that no longer exists. Fix: move the ignore file to `~/.config/git/ignore`
  (git's default lookup; needs no gitconfig entry at all).
- `steamdeck.sh` is broken (`$(shell …)` is Makefile syntax inside a bash script;
  `submodule` missing the `git`). Superseded by the chezmoi flow — delete.
- `aliases` hardcodes `GODOT_PATH=/opt/Godot_v4.7-stable_linux.x86_64` while
  `godot-shortcut.sh` writes a 4.6.3 desktop file pointing elsewhere — exactly the drift
  the new godot script eliminates.
- `export DEBUG=true` in aliases looks accidental (leaks into every program that reads
  `DEBUG`) — drop unless it's intentional.
- Makefile `dotbot-install` target is misnamed (`.PHONY: dotbot-install` but target is
  `dotbot:`, silently overriding the earlier `dotbot` target) — moot after deletion.
- `scripts/ledger_udev_rules.sh`: **dropped** (no longer needed; stays in git history).
- `LeechBlockOptions.txt` and the old README's grub/ydotool notes: keep as reference
  material under `docs/` (not applied by chezmoi), with a note on how to re-import
  the LeechBlock backup.

### 9. Documentation

- `README.md`: what this repo is; the one-line install per OS (same command everywhere);
  the machine matrix (what each OS gets); a **Windows box calling out the two-script
  split** (chezmoi one-liner → WSL bash; `windows\setup.ps1` → admin PowerShell);
  day-2 commands (`chezmoi update`, `chezmoi apply`, `chezmoi cd`, `chezmoi add`,
  `chezmoi diff`).
- `docs/adding-things.md`, one short recipe each:
  - add an alias / env var / directory shortcut (edit `dot_aliases.tmpl` → apply → commit)
  - add a package (edit `packages.yaml` — script re-runs automatically on next apply)
  - start managing a new program's config (`chezmoi add ~/.config/foo/…`)
  - resave GNOME settings (`czsave-dconf`)
  - update Godot to the latest stable (`godot-update`)
  - add a choco package / edit Windows hotkeys (edit `windows/…`, re-run `setup.ps1`)
  - optional extras on a machine that needs them (`install-tailscale`,
    `install-zerotier`, `install-nvidia` — on PATH everywhere, never auto-run)
  - add a new machine type (extend `.chezmoi.toml.tmpl` + `.chezmoiignore`)

## Old Makefile / scripts → where each lands

Every target and script in the old repo, accounted for:

| Old target/script | Disposition |
|---|---|
| `make dnf`, `make flatpak` | → `packages.yaml` + `run_onchange_before_10-packages` (§3) |
| `make oh-my-bash` | → `run_once_before_20-oh-my-bash` (§2) |
| `make dotbot` / `dotbot-install` / `dotbot-terminal` | → chezmoi itself; dotbot submodule deleted |
| `make dotbot-gnome` (input-remapper, bookmarks) | → managed files under `dot_config/`, GUI-only (§5) |
| `make dotbot-godot` (editor settings) | → `dot_config/godot/`, native path (§4) |
| `#dotbot-kde` (commented out) + `dotfiles/kde/` | **dropped** (decided above) |
| `make gitignore-global` | → `dot_config/git/ignore` — git's default path, no config needed (§8) |
| `make zerotier`, `make tailscale` | → **optional** `install-zerotier` / `install-tailscale` in `~/.local/bin`; never auto-run (login is interactive anyway), documented in README |
| `make nvidia` | → **optional** `install-nvidia` in `~/.local/bin`; run manually on NVIDIA machines only (auto-installing kernel modules on non-NVIDIA hardware causes problems) |
| `make dconf-save` / `dconf-load` | → `czsave-dconf` helper / `run_onchange_after_40-dconf` (§5) |
| `make gnome-shell-extensions` | → gnome-extensions-cli in `run_once_after_50-gnome-extras` (§5) |
| `make firefox-policies` | → `run_once_after_50-gnome-extras` (§5) |
| `make desktop-files` + `scripts/install-desktop-files.sh` + `godot-shortcut.sh` | → templated `.desktop` files + icons under `dot_local/share/` (§4) |
| `steamdeck.sh` | **dropped** — was already broken (§8); Steam Deck uses the same one-liner |
| `scripts/ledger_udev_rules.sh` | **dropped** (git history only) |
| `LeechBlockOptions.txt` | → `docs/` as a manual-import backup |
| Old README fix-it notes (grub, ydotool) | → `docs/recovered-notes.md` |

## Migration order & testing

1. **Build** the chezmoi source tree on this machine on branch `chezmoi-migration`
   (items 1–9 above). Old repo untouched on master.
2. **Convert this machine (Fedora GNOME)**: remove dotbot symlinks
   (`~/.bashrc ~/.vimrc ~/.aliases ~/.gitconfig ~/.profile ~/.config/nvim/init.lua`,
   input-remapper + bookmarks links, desktop-file links), then `chezmoi apply -v`.
   Verify: new shell has all aliases/env vars; nvim config loads; `godot`/`godotnet`
   launch and `$GODOT_PATH` resolves; dconf/extensions/input-remapper intact.
3. **Verify idempotency**: second `chezmoi apply` is a no-op; `chezmoi doctor` clean.
4. **Test remaining machines** with the one-liner (branch form:
   `… -- init --apply --branch chezmoi-migration anhdngo`):
   Fedora WSL (packages, aliases, `~/winhome`), Debian server (apt path, no GUI/godot),
   Steam Deck (no sudo/pacman used; flatpak + `~/.local` only).
   On the Windows machine, also run `windows\setup.ps1` in admin PowerShell and verify:
   choco packages installed, hotkeys active after relog, Ctrl+\ toggles the quake terminal.
5. **Finalize**: merge to master, update GitHub repo description/README, delete
   `~/.dotfiles` from converted machines, archive the old `~/Workspace/hotkeys` repo
   (now absorbed into `windows/`), keep dotbot-era files in git history only.

## Risks / notes

- **First apply on a dirty home dir**: chezmoi refuses to overwrite files that differ —
  the README will note `chezmoi apply --force` (or reviewing with `chezmoi diff`) for
  first-run on an old machine. Fresh OS installs won't hit this.
- **dconf dumps are noisy** (they capture window positions, recent files, hardware-specific
  bits). Acceptable to start; a later improvement is scoping the dump to selected paths
  (`/org/gnome/desktop/`, `/org/gnome/shell/`, keybindings) instead of `/`.
- **oh-my-bash installer overwrites `~/.bashrc`**: the install script must run it with
  `--unattended` *before* chezmoi writes bashrc, or restore bashrc after — hence
  `run_once_before_20-…` ordering (before scripts run prior to file application).
- **Steam Deck SteamOS updates** wipe anything outside `/home` — everything this plan
  installs there lives in `/home`, so a re-`chezmoi apply` after major updates is the
  only maintenance.
