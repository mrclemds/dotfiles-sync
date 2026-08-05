# dotfiles-sync

A safe POSIX shell updater for a Git-backed dotfiles repository. It fetches and
stages changes first; applying them to `$HOME` is a separate, backup-protected
operation by default.

## Install

Install the latest public release with one command. It needs no GitHub CLI
account or token and prompts for your dotfiles repository URL:

```sh
curl -fsSL https://github.com/mrclemds/dotfiles-sync/releases/latest/download/install-dotfiles-sync.sh | bash
```

For unattended installation, provide the remote explicitly:

```sh
curl -fsSL https://github.com/mrclemds/dotfiles-sync/releases/latest/download/install-dotfiles-sync.sh | bash -s -- --remote git@github.com:YOUR_USER/dotfiles.git
```

The bootstrap downloads and validates the release archive before running its
installer. The installer needs `git` and chooses the best available user
scheduler: systemd on Linux, launchd on macOS, then cron or a foreground
fallback. It never requires root. Use `--branch NAME` when the dotfiles
repository should not use its remote default branch.

## First Sync

```sh
dotfiles-sync sync
dotfiles-sync status
dotfiles-sync apply
```

`sync` fetches, fast-forwards, validates, and stages a revision. In the default
`SYNC_APPLY_MODE=manual`, it does **not** modify `$HOME`. Review `status`, then run
`apply` to deploy the staged revision. Every apply creates a rollback-capable
backup before replacing files.

Managed paths are relative to the dotfiles repository root. For example,
`.config/opencode/` deploys to `~/.config/opencode/`.

## Everyday Commands

| Command | Purpose |
| --- | --- |
| `dotfiles-sync sync` | Fetch, stage, and push local `store`/`remove` commits. |
| `dotfiles-sync check` | Report remote status without pull, apply, or push. |
| `dotfiles-sync status` | Show the applied and pending revisions. |
| `dotfiles-sync apply` | Deploy the pending revision with a backup. |
| `dotfiles-sync rollback` | Restore the newest backup. |
| `dotfiles-sync self-update` | Download the latest public CLI release over HTTPS. |
| `dotfiles-sync help COMMAND` | Show command-specific help. |

`self-update` updates only the deployed CLI under
`~/.local/share/dotfiles-sync`. It never modifies the source checkout or your
managed dotfiles repository, and it does not require GitHub CLI authentication.
It will not downgrade an installation that is newer than the latest published
release.

## Managing Files

Use `store` to explicitly import files from `$HOME` into the managed repository:

```sh
dotfiles-sync store ~/.bashrc ~/.zshrc
dotfiles-sync store ~/.config/opencode/
```

`store` accepts only paths inside `$HOME`, requires a clean managed checkout,
and creates a local Git commit. With the default `STORE_PUSH_MODE=manual`, `sync`
pushes the reviewed commit later; set `STORE_PUSH_MODE=automatic` to push it
immediately. Existing destination files require an interactive overwrite
confirmation.

For agents and other non-interactive callers, supply a message. If replacement
is needed, first request a dry run and then pass its confirmation token:

```sh
dotfiles-sync store --dry-run --non-interactive --message "Update configuration" ~/.config/example/config
dotfiles-sync store --non-interactive --confirm-overwrite TOKEN --message "Update configuration" ~/.config/example/config
```

Use `remove` to stop managing a tracked regular file while leaving the local
file in place:

```sh
dotfiles-sync remove ~/.config/opencode/obsolete.json
```

Add `--remove-original` only when the local file should also be removed. That
operation creates a backup and requires an interactive confirmation or a dry-run
token in non-interactive use.

## Configuration

Runtime configuration is stored at `~/.config/dotfiles-sync/config`. The
installer creates it on first use; the tracked template is
`.config/dotfiles-sync/config.example`.

Important settings:

| Setting | Default | Meaning |
| --- | --- | --- |
| `REMOTE` | required | Git remote for the managed dotfiles repository. |
| `BRANCH` | remote default | Managed branch. |
| `SYNC_APPLY_MODE` | `manual` | Apply staged remote changes during `sync` when `automatic`. |
| `STORE_PUSH_MODE` | `manual` | Push after `store` when `automatic`; `manual` and `prompt` defer to `sync`. |
| `POLL_INTERVAL` | `21600` | Automatic polling interval in seconds. |
| `IGNORE_FILE` | runtime ignore file | Positive patterns never staged or applied. |
| `AFTER_APPLY_HOOK` | conventional path | Optional tracked post-apply POSIX hook. |

Configuration is POSIX shell syntax. Path values must expand to absolute paths;
for example, `${HOME:-/tmp}/.config/dotfiles-sync/ignore` is valid.

### Ignore Rules

`~/.config/dotfiles-sync/ignore` contains positive Gitignore-style patterns for
repository-relative paths that must never be staged or applied. It supports
comments, blank lines, and `*` globs; `!` negation is deliberately unsupported.
Add the same paths to the managed repository's `.gitignore` so machine-local
state never reaches Git.

### After-Apply Hook

When the tracked `.config/dotfiles-sync/after-apply` exists, `apply` validates
it with `sh -n`, deploys it with the revision, records that revision as applied,
then runs the deployed hook with `sh`. The hook receives
`DOTFILES_SYNC_REPO_DIR` and `DOTFILES_SYNC_REVISION`.

Hooks can intentionally change `$HOME`; keep them small and idempotent. They do
not run during `sync`, `check`, or `self-update`. Disable the conventional path
with an empty `AFTER_APPLY_HOOK` setting.

## Safety Model

- `check` does not pull, apply, or push.
- `sync` rejects dirty checkouts and non-fast-forward updates.
- `sync` stages only tracked repository-root files.
- `apply` validates staged files, writes through temporary files, and preserves
  a rollback-capable backup.
- `store` and `remove` accept only paths inside `$HOME`.
- Never track credentials, private keys, tokens, or machine-local state.

Set `SYNC_APPLY_MODE=automatic` or `STORE_PUSH_MODE=automatic` only after reviewing and
trusting the relevant workflow. With `STORE_PUSH_MODE=automatic`, a successful
`store` immediately pushes its commit; otherwise the next `sync` pushes it.

## Releases

Releases are created through the manual `Release` workflow from a protected
source branch. Supply a full semantic tag such as `v1.0.0` or `v1.2.3`. The
workflow requires a successful `Test` run for the exact source commit, validates
the source branch, serializes publication, creates or verifies the tag, and
publishes `dotfiles-sync.tgz`.

The initial `v1.0.0` release creates `release/v1` from `main`. To start a
diverging minor line, run `Create Minor Maintenance Branch` from `release/v1`
with `v1.2`; it creates `release/v1.2`. Then release `v1.2.0` from that branch.
Patch releases use the matching existing maintenance branch.

Release archives contain the installer bootstrap, CLI, GPL-3.0 license, release
metadata, configuration examples, migrations, scheduler templates, and this
README. Each release also publishes the standalone `install-dotfiles-sync.sh`
bootstrap asset and a generated Conventional Commit changelog.

### Breaking Updates

Breaking runtime configuration or state changes require an idempotent POSIX
migration under `.config/dotfiles-sync/migrations/vMAJOR.MINOR.PATCH.sh`.
Migrations may change only dotfiles-sync runtime configuration/state and must
pass `sh -n`. Self-update backs up configuration before running migrations.

The release workflow keeps the two newest migrations and opens cleanup pull
requests for older ones. Updates spanning more than two major versions require
installing an intermediate release first.

### Backports

Implement fixes on `main` first. For an intentional compatible maintenance
backport, add this trailer after the commit reaches `main`:

```text
Backport-To: release/v1
```

The Backport workflow cherry-picks the commit to an `automation/*` branch and
opens a pull request for the requested `release/vMAJOR[.MINOR]` target.

## Development

Run the isolated updater suite for updater or workflow changes:

```sh
sh tests/test_dotfiles_sync.sh
```

CI also validates POSIX syntax, ShellCheck, and GitHub Actions workflows on
pull requests and pushes to `main`, `release/*`, and `automation/*`.

Use Conventional Commit subjects:

```text
type(optional-scope): short imperative description
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution requirements,
[SECURITY.md](SECURITY.md) for private vulnerability reporting, and
[docs/public-release-checklist.md](docs/public-release-checklist.md) for
repository security configuration.

## License

Copyright (C) 2026 mrclemds. Released under the
[GNU General Public License v3.0](LICENSE).
