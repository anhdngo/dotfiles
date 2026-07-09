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

Available flags: `.gui` (Fedora GNOME), `.wsl`, `.steamdeck`, `.headless`.

## Add a package

Edit `.chezmoidata/packages.yaml` — pick the right list (`dnf.common`,
`dnf.gui`, `apt`, `flatpak.gui`, `flatpak.deck`). The package script re-runs
automatically on the next `chezmoi apply` because its rendered content changed.

## Add a Windows (choco) package

Add a line to `windows/choco-packages.txt`, then re-run `windows-setup`
(from WSL) or `windows\setup.ps1` (from Windows).

## Edit Windows hotkeys

Edit `windows/hotkeys.ahk`, then re-run `windows-setup` — it re-copies the
script to the Windows side and relaunches it.

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
