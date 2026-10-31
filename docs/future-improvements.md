# Future improvements

Roughly in priority order.

- **Migrate actual secrets.** The plumbing is done (bw CLI everywhere, age
  encryption configured, `bwu`/`install-age-key` helpers) — now move the real
  secrets in: `chezmoi add --encrypt` the SSH keys, convert token-bearing
  configs to bitwarden-backed templates. See docs/adding-things.md.
- **Pin/verify Godot downloads.** `godot-update` trusts the GitHub release; the
  releases ship SHA-512 sums that could be verified after download. Could also
  add a `godot-update <version>` form for pinning/downgrading.
- **CI on the repo.** GitHub Action running `chezmoi doctor`/`chezmoi apply
  --dry-run` in containers for each target OS, plus `shellcheck` on scripts and
  template lint — catches breakage before it reaches a machine.
- **GNOME extension updates + enabling.** `gext` installs extensions but the
  extras script is run_once; move to run_onchange keyed on the extension list,
  and explicitly `gext enable` each one.
- **Steam Deck extras.** If desktop-mode customization is ever wanted again,
  add a curated (small) set of KDE configs gated on `.steamdeck` rather than
  resurrecting the old Plasma-5 dump.
- **Bootstrap SSH/GPG.** New-machine setup still needs keys before `git push`
  works; document or automate key provisioning (e.g. via a password manager).
- **Firefox config beyond policies.** user.js / profile settings are not
  managed; policies.json only covers a few enterprise-style options.
- **Auto-update robustness.** The daily `chezmoi-update.timer` runs
  non-interactively, so a changed package list (which needs sudo) makes that
  run fail until the next manual `chezmoi apply`. Could split package installs
  out of the timer path or use a passwordless-sudo allowlist for dnf/apt.

