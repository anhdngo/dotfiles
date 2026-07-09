# Future improvements

Roughly in priority order.

- **Scope the dconf dump.** `dconf dump /` captures noise (window positions,
  recent files, hardware-specific settings) and loading it on a second desktop
  could clobber per-machine state. Dump only selected paths instead
  (`/org/gnome/desktop/`, `/org/gnome/shell/`, `/org/gnome/settings-daemon/`
  keybindings) and split them into per-area files.
- **Pin/verify Godot downloads.** `godot-update` trusts the GitHub release; the
  releases ship SHA-512 sums that could be verified after download. Could also
  add a `godot-update <version>` form for pinning/downgrading.
- **CI on the repo.** GitHub Action running `chezmoi doctor`/`chezmoi apply
  --dry-run` in containers for each target OS, plus `shellcheck` on scripts and
  template lint — catches breakage before it reaches a machine.
- **Secrets management.** chezmoi has first-class support for age encryption
  and password managers (e.g. Bitwarden) — useful for SSH config, tokens, or
  the git email on work machines.
- **Auto-update.** A systemd user timer running `chezmoi update` periodically
  so machines stay in sync without manual pulls (especially the headless
  server and Steam Deck).
- **Native chezmoi on Windows.** chezmoi runs on Windows; the `windows/` half
  (choco list, hotkeys, terminal settings) could become a real chezmoi target
  with PowerShell run-scripts instead of a separate manual setup.ps1.
- **GNOME extension updates + enabling.** `gext` installs extensions but the
  extras script is run_once; move to run_onchange keyed on the extension list,
  and explicitly `gext enable` each one.
- **Godot editor settings version drift.** `editor_settings-4.4.tres` is
  version-specific; new Godot majors create new files. Consider templating the
  filename or symlinking the newest.
- **Steam Deck extras.** If desktop-mode customization is ever wanted again,
  add a curated (small) set of KDE configs gated on `.steamdeck` rather than
  resurrecting the old Plasma-5 dump.
- **Bootstrap SSH/GPG.** New-machine setup still needs keys before `git push`
  works; document or automate key provisioning (e.g. via a password manager).
- **Firefox config beyond policies.** user.js / profile settings are not
  managed; policies.json only covers a few enterprise-style options.
