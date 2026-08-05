---
name: dotfiles-safety
description: Use when changing dotfiles, bin/dotfiles-sync, staging, applying, rollback, services, or machine-specific shell configuration.
---

# Dotfiles Safety

Apply this skill to all dotfiles and updater work.

## Repository Boundaries

- Treat the Git checkout as source material, not as the live home directory.
- Use tracked files at the managed repository root as the deployment boundary.
- Apply positive glob patterns from the configured runtime ignore file before
  staging or applying; keep those paths in `.gitignore` too.
- Treat `store` as an explicit, interactive import from `$HOME`; validate path
  containment and confirm overwrites. It may push only when `STORE_PUSH_MODE=automatic`.
- For non-interactive `store`, allow an optimistic first attempt only when no
  overwrite is needed; require a dry-run overwrite token before replacement.
- Keep `check` read-only apart from refreshing remote tracking metadata; `sync`
  performs the bidirectional pull and push workflow. `STORE_PUSH_MODE=automatic` also
  pushes a successful `store` commit.
- Never add credentials or private machine state to tracked files.
- Keep generated state under the configured XDG state directory.
- Updater configuration belongs under `.config/dotfiles-sync/` in the
  repository and `~/.config/dotfiles-sync/` at runtime.
- When asked to commit, use Conventional Commits:
  `type(optional-scope): short imperative description`.
- Implement fixes on `main` first. Use a `Backport-To: release/vMAJOR[.MINOR]`
  commit trailer only for intentional compatible maintenance backports.

## Update Lifecycle

The safe lifecycle is:

1. Check for a clean worktree.
2. For the configured dotfiles repository, fetch and accept only a
   fast-forward update.
3. Copy configured files into a revision-specific pending directory.
4. Validate staged files before deployment.
5. Back up current destinations.
6. Copy through temporary files and rename into place.
7. Record the applied revision and retain rollback data.

Never apply directly from a remote ref or from an unvalidated checkout. Run an
after-apply hook only when it is tracked, non-ignored, validated, and deployed
with the applied revision.

CLI self-updates must download a validated HTTPS release archive and atomically
replace only the deployed CLI directory. They must not modify a source checkout.

For breaking updater runtime-config or state changes, add an idempotent POSIX
migration under `.config/dotfiles-sync/migrations/vMAJOR.MINOR.PATCH.sh`. It may
modify only updater config/state and must pass `sh -n`.

## Shell Portability

- Use POSIX syntax in shared scripts.
- Guard interactive-only commands and options.
- Do not assume `systemd`, `cron`, `zsh`, GNU utilities, or a writable system
  directory.
- Quote paths and variables, especially paths derived from configuration.

## Verification

Use `sh -n`, ShellCheck, `bash -n`, `zsh -n`, and `git diff --check` as
appropriate. For behavior changes, test both the no-update path and a staged
update path, including failure before any home-directory replacement.

Run and extend `tests/test_dotfiles_sync.sh` for updater behavior changes.

When shared policy changes, update `AGENTS.md`,
`.github/copilot-instructions.md`, `.agents/skills/`, and the relevant OpenCode
instructions so Codex, Copilot, and OpenCode remain consistent.
