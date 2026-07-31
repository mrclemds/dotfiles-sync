# dotfiles-sync Project Instructions

This repository contains the `dotfiles-sync` updater. Keep changes safe to
deploy across multiple machines.

## General Rules

- Inspect the working tree before editing and preserve unrelated user changes.
- Keep secrets, tokens, private keys, machine-specific credentials, and local
  state out of Git. Update `.gitignore` when adding a new local-only path.
- Prefer small, reversible changes over broad rewrites.
- Use POSIX shell for updater code unless a Bash or Zsh-specific feature is
  required and explicitly documented.
- Never silently overwrite a user's local configuration. Use backups,
  allowlists, staging, or an explicit migration.
- When creating a commit, use Conventional Commits: `type(optional-scope): short
  imperative description`.
- Do not commit, push, or create pull requests unless explicitly requested.
- When shared behavior changes, keep `.github/copilot-instructions.md` and the
  OpenCode files under `.opencode/`, and Codex skills under `.agents/skills/`
  aligned with these rules.

## Validation

- Run `sh -n` and ShellCheck for shell scripts when available.
- Validate Bash files with `bash -n` and Zsh files with `zsh -n` when available.
- Run `git diff --check` before reporting completion.
- Review `git status` and the complete diff after edits.

## Updater Invariants

- `sync` pulls and stages; it must not modify files in `$HOME` in manual mode.
- `apply` is the only normal operation that changes managed files in `$HOME`.
- `store` is the explicit operation that copies files from `$HOME` into the
  configured dotfiles root and creates a commit; it must validate that sources are
  inside `$HOME`.
- Configured dotfiles updates must be fast-forward only and dirty checkouts must
  be rejected.
- CLI self-updates must download a validated HTTPS release archive and replace
  only the deployed CLI directory; they must not modify a source checkout.
- Add a versioned POSIX migration under `.config/dotfiles-sync/migrations/` for
  breaking updater runtime-config or state changes. Migrations must be
  idempotent, limited to updater config/state, and validated with `sh -n`.
- Keep the two newest migration scripts; let the release workflow create cleanup
  pull requests for older scripts. Do not delete migrations manually.
- `sync` may pull fast-forward changes and push local commits; `check` must not
  pull, apply, or push.
- Every apply must retain a rollback-capable backup.
- Only tracked files at the managed repository root may be copied to the
  user's home directory.
- Run an after-apply hook only when it is tracked, non-ignored, validated, and
  deployed with the applied revision.
- Updater configuration belongs under `.config/dotfiles-sync/` in the
  repository and `~/.config/dotfiles-sync/` at runtime.
