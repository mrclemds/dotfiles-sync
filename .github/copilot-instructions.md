# dotfiles-sync Project Instructions

This repository contains the `dotfiles-sync` updater. Changes must remain safe
to deploy across multiple Linux distributions, WSL, macOS, containers, and
GitHub Codespaces.

## Shared Rules

- Inspect the working tree before editing and preserve unrelated changes.
- Never add secrets, tokens, private keys, credentials, or machine-local state.
- Keep changes small, reversible, and documented.
- Use POSIX shell for shared updater code unless a Bash or Zsh feature is
  explicitly required and guarded.
- Never silently overwrite user configuration.
- When creating a commit, use Conventional Commits: `type(optional-scope): short
  imperative description`.
- Implement every change on a dedicated branch; never commit implementation
  changes directly on `main`. For an intentional compatible maintenance
  backport, add `Backport-To: release/vMAJOR[.MINOR]` in the commit body; do not
  use it for unrelated future work.
- Create `release/vMAJOR.MINOR` only when the user explicitly requests a
  diverging minor maintenance line. A minor version request alone releases from
  the existing major maintenance branch.
- Use semantic release levels consistently: new backward-compatible features
  are minor releases, breaking changes are major releases, and fixes only are
  patch releases.
- Manage the full change lifecycle: create the dedicated branch, commit and
  push the change, create its pull request, wait for required checks to pass,
  and merge the pull request. The job is not complete until the pull request
  has been fully managed and merged, unless the user explicitly pauses or
  declines a step.
- If the requested change or repository workflow requires a major, minor, or
  patch release, inform the user and ask for approval before releasing it. If
  the user requests a release, manage the appropriate semantic version
  release as part of the same workflow.

## Dotfiles Sync Contract

- `sync` fetches and stages; in manual mode it must not modify `$HOME`.
- `apply` is the normal operation that changes managed files in `$HOME`.
- `apply --force` may recover stale state by rebuilding from the clean managed
  checkout `HEAD`; it must retain validation, backups, and applied-state updates.
- Accept only fast-forward updates for the configured dotfiles repository and
  reject dirty checkouts.
- CLI self-updates must download a validated HTTPS release archive and replace
  only the deployed CLI directory; never update a source checkout.
- For breaking updater runtime-config or state changes, create an idempotent
  POSIX migration under `.config/dotfiles-sync/migrations/vMAJOR.MINOR.PATCH.sh`.
  Migrations may modify only updater config/state and must pass `sh -n`.
- Validate staged files before applying them.
- Keep a rollback-capable backup for every apply.
- Copy only tracked files at the managed repository root.
- Run an after-apply hook only when it is tracked, non-ignored, validated, and
  deployed with the applied revision.
- Exclude positive glob patterns from the configured runtime ignore file before
  staging or applying, and keep those paths in `.gitignore` too.
- Treat `store` as an explicit import from `$HOME`; validate containment and
  confirm overwrites. It may push only when `STORE_PUSH_MODE=automatic`.
- Non-interactive `store` and `remove` calls must provide `--message`; never use
  generated commit messages for agent actions.
- Agents adding themselves to a `store` commit must use the dedicated
  `--co-owner NAME <EMAIL>` argument. The CLI must emit a canonical
  `Co-authored-by: NAME <EMAIL>` trailer, validate identity input, and reject
  malformed, duplicate, or option-injection input; never hand-edit trailers.
- Non-interactive `store` may proceed only without overwrites, or after a
  dry-run overwrite token is explicitly supplied; never use an overwrite bypass.
- `sync` is the bidirectional pull/push operation; `STORE_PUSH_MODE=automatic` also
  pushes a successful `store` commit. `check` only refreshes and reports remote
  status without pulling, applying, or pushing.
- Keep runtime configuration in `~/.config/dotfiles-sync/` and runtime state in
  the XDG state directory.

## Compatibility

When changing updater behavior, service setup, or shell files, update the
relevant documentation and examples. Keep `AGENTS.md`, this file, and the
OpenCode agents/skills under `.opencode/` and Codex skills under
`.agents/skills/` aligned when their shared rules change.

## Validation

Run the relevant checks when available:

```sh
sh -n bin/dotfiles-sync
shellcheck bin/dotfiles-sync
sh tests/test_dotfiles_sync.sh
bash -n .bashrc .bash_aliases
zsh -n .zshrc
git diff --check
```
