# Adding things

For most changes: edit the file from the README's "Where things live" table,
run `chezmoi apply`, then commit and push. Below are the ones with more to know.

## Template flags

Templates (`*.tmpl`) can check the machine: `.gui` (Fedora GNOME), `.wsl`,
`.steamdeck`, `.headless` (Debian server or WSL), `.windows`,
`.chezmoi.os` (`"darwin"` for macOS), and `.profile`. Read the profile as
`default "gamedev" (get . "profile")` so older configs without it still work.

```
{{ if .gui }}alias e="nautilus . & disown"{{ end }}
```

## Packages

In `.chezmoidata/packages.yaml`, lists ending in `gamedev` install only on the
gamedev profile, and lists named `ai` skip `coding-noai`. Everything else
installs on every profile, so keep it safe for a work computer. Packages are
never uninstalled.

## Claude Code MCP servers

Add them to `.chezmoidata/claude.yaml`. Removing one there doesn't unregister
it; run `claude mcp remove -s user <name>`.

## A new program's config

`chezmoi add ~/.config/someprogram/config.toml`. If it's only for some
machines, add it to `.chezmoiignore`.

## GNOME settings and extensions

`czsave-dconf` saves only the paths listed in `.chezmoidata/dconf.yaml`. If a
setting isn't saved, find its path with `dconf watch /` and add it there.

New extensions go in `gnome_extensions` in `packages.yaml` (the UUID is on its
extensions.gnome.org page). Already set-up machines need
`gext install <uuid>`, since that script only runs once.

## Obsidian vault launchers (GNOME)

Vaults are in `.chezmoidata/obsidian.yaml`. To add one, add an entry there and
copy an existing pair of `dot_local/share/applications/obsidian-<key>.desktop.tmpl`
and `dot_local/share/icons/obsidian-<key>.svg.tmpl`.

## Secrets

**Files (SSH keys):** `chezmoi add --encrypt ~/.ssh/id_ed25519`. They're stored
age-encrypted in the repo. Each machine needs the age key before `chezmoi apply`
can decrypt them. The key is the Bitwarden secure note `chezmoi-age-key`; on a
new machine run `bw login`, `bwu`, `install-age-key`, then `chezmoi apply`.

**Tokens:** in a `.tmpl` file, use
`{{ (bitwarden "item" "github.com").login.password }}`. The vault has to be
unlocked (`bwu`) for apply to work, which the Linux daily update can't do, so
use age files on machines that update by themselves.

## A new machine type or profile

1. Machine type: detect it in `.chezmoi.toml.tmpl` and add a flag under
   `[data]`. Profile: add it to the `promptChoiceOnce` list there.
2. Gate files in `.chezmoiignore`, and packages and scripts on the new flag or
   profile.
3. On an existing machine, `chezmoi init` regenerates the config from the
   template.
