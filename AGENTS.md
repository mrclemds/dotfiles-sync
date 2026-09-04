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
- Implement changes on `main` first. For an intentional compatible maintenance
  backport, add `Backport-To: release/vMAJOR[.MINOR]` in the commit body after it
  is ready for the backport workflow; never add it to unrelated future work.
- Create `release/vMAJOR.MINOR` only when the user explicitly requests a
  diverging minor maintenance line. A minor version request alone releases from
  the existing major maintenance branch.
- Use semantic release levels consistently: new backward-compatible features
  are minor releases, breaking changes are major releases, and fixes only are
  patch releases.
- Do not commit, push, or create pull requests unless explicitly requested.
- When shared behavior changes, keep `.github/copilot-instructions.md` and the
  OpenCode files under `.opencode/`, and Codex skills under `.agents/skills/`
  aligned with these rules.

## Validation

- Run `sh -n` and ShellCheck for shell scripts when available.
- Validate Bash files with `bash -n` and Zsh files with `zsh -n` when available.
- Run `sh tests/test_dotfiles_sync.sh` for updater behavior changes and extend it
  with coverage for new behavior.
- Run `git diff --check` before reporting completion.
- Review `git status` and the complete diff after edits.

## Updater Invariants

- `sync` pulls and stages; it must not modify files in `$HOME` in manual mode.
- `apply` is the only normal operation that changes managed files in `$HOME`.
- `apply --force` may rebuild the pending snapshot from the clean managed
  checkout `HEAD` when state is stale; it must validate, back up, overwrite,
  and update applied state just like a normal apply.
- `store` is the explicit operation that copies files from `$HOME` into the
  configured dotfiles root and creates a commit; it must validate that sources are
  inside `$HOME`.
- Non-interactive `store` and `remove` calls must provide `--message`; do not use
  generated commit messages for agent actions.
- Agent-authored `store` commits may add the agent as a co-owner with the
  dedicated `--co-owner NAME <EMAIL>` argument. The implementation must emit a
  canonical `Co-authored-by: NAME <EMAIL>` trailer, validate the identity
  without accepting arbitrary commit-argument injection, and reject duplicate
  or malformed trailers. Do not hand-edit trailers or pass raw `git commit`
  options.
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

## Co-Owner Implementation Plan

- Add `--co-owner NAME <EMAIL>` to `store` only; keep it repeatable for multiple
  agents and reject it for `remove` unless a later requirement explicitly
  expands the scope.
- Parse and validate the name/email as one identity, construct trailers with
  Git's trailer-safe mechanism, and preserve the supplied commit message.
- Cover interactive and non-interactive `store`, dry runs, malformed input,
  duplicate identities, and the resulting commit metadata in
  `tests/test_dotfiles_sync.sh`.
- Update `README.md`, help output, and all mirrored agent guidance when the CLI
  behavior is implemented; run shell syntax, ShellCheck, focused tests, and
  `git diff --check`.
