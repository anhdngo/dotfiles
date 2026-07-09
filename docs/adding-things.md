# Adding things

Quick recipes. In all cases: edit → `chezmoi apply` → commit & push from the
repo (`czd` to get there).

## Add an alias, env var, or directory shortcut

Edit `dot_aliases.tmpl` (`chezmoi edit ~/.aliases` also works). Directory
shortcuts follow the pattern:

```sh
alias ws='cd $WS'
```

Wrap machine-specific entries in a template conditional:

```
{{ if .gui }}alias e="nautilus . & disown"{{ end }}
```

Available flags: `.gui` (Fedora GNOME), `.wsl`, `.steamdeck`, `.headless`
(Debian server or WSL — no Godot, linger for the update timer), `.windows`,
and `.profile` (`"coding"` or `"gamedev"` — in templates read it defensively
as `default "gamedev" (get . "profile")` so machines with a pre-profile config
still render).

## Add a package

Edit `.chezmoidata/packages.yaml` — pick the right list (`dnf.common`,
`dnf.gui`, `apt`, `flatpak.gui`, `flatpak.deck`, `choco.common`). Lists with a
`gamedev` suffix only install on gamedev-profile machines — put Godot/art/media
things there, work-computer-safe things in the plain lists. The package script
re-runs automatically on the next `chezmoi apply` because its rendered content
changed. (On Windows the choco script self-elevates.)

## Edit Windows hotkeys

Edit the managed file (in the repo:
`AppData/.../Start Menu/Programs/Startup/hotkeys.ahk`), then `chezmoi apply`
on the Windows side — a run_onchange script relaunches AutoHotkey with the
new hotkeys.

## Change Windows Terminal settings

Either edit the managed `settings.json` under
`AppData/Local/Packages/Microsoft.WindowsTerminal_.../LocalState/` and apply,
or tweak in the Terminal UI and run `chezmoi re-add` on Windows to pull the
result back into the repo (Terminal rewrites the file, so `chezmoi diff` will
show drift until you do).

## Change a machine's profile (coding ↔ gamedev)

The `chezmoi init` prompt only fires once per machine. To switch later, edit
`profile` under `[data]` in `~/.config/chezmoi/chezmoi.toml`, then
`chezmoi apply`. Note the switch only affects what chezmoi manages going
forward — already-installed packages aren't uninstalled.

## Start managing a new program's config

```sh
chezmoi add ~/.config/someprogram/config.toml
```

This copies the file into the repo with the right `dot_` name. If it should
only apply to some machines, add it to the conditional section of
`.chezmoiignore`.

## Save changed GNOME settings

```sh
czsave-dconf     # dumps the scoped dconf paths into the repo's dconf/ dir
```

Then review with `git diff` and commit. Other GNOME machines pick it up on
`chezmoi update` (the dconf script re-runs because a file's hash changed).

Only the paths listed in `.chezmoidata/dconf.yaml` are saved/loaded (desktop,
shell + extensions, settings-daemon, mutter, nautilus, ddterm) — deliberate,
to keep runtime noise like recent files and window state from syncing. If a
setting you care about lives elsewhere (`dconf watch /` shows where a setting
lands as you change it), add its path to `dconf.yaml` and run `czsave-dconf`.

## Manage a secret (SSH keys, tokens)

Two mechanisms, pick per secret:

**age-encrypted files** (offline, survives the auto-update timer) — for SSH
keys and other rarely-changing files:

```sh
chezmoi add --encrypt ~/.ssh/id_ed25519
chezmoi add --encrypt ~/.ssh/id_ed25519.pub   # pub key can also go in plain
chezmoi apply && git -C "$(chezmoi source-path)" diff --stat
```

The file is stored age-encrypted in the repo (safe to push) and decrypted to
the right place on apply. The identity at `~/.config/age/key.txt` is
per-machine and never committed: store it in Bitwarden as a secure note named
`chezmoi-age-key` (paste the contents of key.txt), and on each new machine run
`bw login`, `bwu`, `install-age-key` right after the chezmoi one-liner.
Machines without the age binary are fine — chezmoi has a builtin.

> Until the age key is on a machine, `chezmoi apply` fails on encrypted files.
> So: one-liner → `bw login` → `bwu` → `install-age-key` → `chezmoi apply`.

**Bitwarden-backed templates** (live vault lookups) — for tokens you rotate:

```
{{ (bitwarden "item" "github.com").login.password }}
{{ (bitwardenFields "item" "my-server").api_token.value }}
```

Put these in a `.tmpl` file, then `bwu && chezmoi apply` (the vault must be
unlocked to render them — including by the daily update timer, so prefer age
for anything on headless machines).

## Add a GNOME shell extension

Add its UUID to `gnome_extensions` in `.chezmoidata/packages.yaml`. The UUID is
on the extension's extensions.gnome.org page (or in the URL of its review page).
Note the extras script is `run_once`, so on already-set-up machines install it
with `gext install <uuid>` manually.

## Add a new machine type

1. Add a flag in `.chezmoi.toml.tmpl` (detect via `.chezmoi.osRelease.id`,
   kernel string, hostname, …).
2. Gate files in `.chezmoiignore` and script sections/templates on the flag.
3. On an existing machine, `chezmoi init` (no URL) regenerates the local config
   from the template.

## Add a new profile

1. Add the choice to the `promptChoiceOnce` list in `.chezmoi.toml.tmpl`.
2. Gate package lists in `packages.yaml` (add a suffixed list + template
   conditionals in the package scripts) and files in `.chezmoiignore` on
   `.profile`, defaulting missing values: `default "gamedev" (get . "profile")`.
3. Existing machines keep their stored profile; new ones get the prompt.
