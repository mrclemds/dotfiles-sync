---
applyTo: "dotfiles/**,bin/**,.config/**,systemd/**,launchd/**"
---

for dotfiles and updater changes, preserve Bash/Zsh portability, the staged
`sync` then `apply` lifecycle, the configured-root deployment boundary, rollback
backups, and the tracked after-apply hook boundary. `check` is read-only and
must report missing or differing tracked, non-ignored files against `$HOME`,
including which copy was updated last when timestamps allow that comparison.
User-level updater configuration belongs under `.config/dotfiles-sync/` in the
repository and `~/.config/dotfiles-sync/` at runtime.
