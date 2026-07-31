---
name: dotfiles-safety
description: Use when changing dotfiles, bin/dotfiles-sync, staging, applying, rollback, services, or machine-specific shell configuration.
---

# Dotfiles Safety

Apply this skill to all dotfiles and updater work.

## Repository Boundaries

- Treat the Git checkout as source material, not as the live home directory.
- Use tracked files under `DOTFILES_ROOT` (default `home/`) as the deployment
  boundary.
- Apply positive glob patterns from the configured runtime ignore file before
  staging or applying; keep those paths in `.gitignore` too.
- Treat `store` as an explicit, interactive import from `$HOME`; validate path
  containment, confirm overwrites, and do not push from `store` itself.
- For non-interactive `store`, allow an optimistic first attempt only when no
  overwrite is needed; require a dry-run overwrite token before replacement.
- Keep `check` read-only apart from refreshing remote tracking metadata; only
  `sync` performs the bidirectional pull and push workflow.
- Never add credentials or private machine state to tracked files.
- Keep generated state under the configured XDG state directory.
- Updater configuration belongs under `.config/dotfiles-sync/` in the
  repository and `~/.config/dotfiles-sync/` at runtime.

## Update Lifecycle

The safe lifecycle is:

1. Check for a clean worktree.
2. Fetch and accept only a fast-forward update.
3. Copy configured files into a revision-specific pending directory.
4. Validate staged files before deployment.
5. Back up current destinations.
6. Copy through temporary files and rename into place.
7. Record the applied revision and retain rollback data.

Never apply directly from a remote ref or from an unvalidated checkout. Run an
after-apply hook only when it is tracked, non-ignored, validated, and deployed
with the applied revision.

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

When shared policy changes, update `AGENTS.md`,
`.github/copilot-instructions.md`, `.agents/skills/`, and the relevant OpenCode
instructions so Codex, Copilot, and OpenCode remain consistent.
