---
applyTo: "dotfiles/**,bin/**,.config/**,systemd/**,launchd/**"
---

For dotfiles and updater changes, preserve Bash/Zsh portability, the staged
`sync` then `apply` lifecycle, the configured-root deployment boundary, rollback
backups, and the tracked after-apply hook boundary. User-level updater
configuration belongs under `.config/dotfiles-sync/` in the repository and
`~/.config/dotfiles-sync/` at runtime.
