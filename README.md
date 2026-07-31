# dotfiles-sync

This repository contains the POSIX shell updater for a Git-hosted dotfiles
repository. It stages changes and can optionally apply them to a user's home
directory.

## Repository Layout

```text
dotfiles/                        Local checkout of the managed dotfiles repository
.config/dotfiles-sync/           Updater configuration example
.config/dotfiles-sync/ignore.example
                                  Runtime deployment ignore-pattern example
bin/dotfiles-sync                Updater and installer
systemd/                         Linux systemd user service and timer
launchd/                         macOS launch agent template
.opencode/                       OpenCode agents and skills
.agents/skills/                  Codex-compatible project skills
.github/                         GitHub Copilot instructions
```

Updater configuration belongs under `.config/dotfiles-sync/` in the repository
and under `~/.config/dotfiles-sync/` at runtime. The configured remote is
cloned into `dotfiles/`; its repository root contains the managed files.

## Updater

`bin/dotfiles-sync` supports:

```text
install    Install or repair the command and register a user scheduler
uninstall  Remove the command, scheduler, and optional runtime configuration
self-update Download and install the latest CLI release
store      Copy local HOME files into the repository root, then create a Git commit
sync       Pull, stage/apply, and push updates in both directions
check      Fetch remote metadata and report status without pull/apply/push
apply      Apply the staged update to $HOME
status     Show applied and pending revisions
rollback   Restore the most recent backup, or a specified backup
daemon     Poll continuously in the foreground
help       Show command usage
```

The default workflow is safe and manual:

```sh
bin/dotfiles-sync install --remote git@github.com:YOUR_USER/dotfiles.git
dotfiles-sync sync
dotfiles-sync status
dotfiles-sync apply
```

Use `dotfiles-sync --help` for the complete command reference, including
`store` options. `install` is idempotent: it refreshes the installed executable
and scheduler configuration. Use `dotfiles-sync self-update` to download and
validate the latest CLI release. It does not stage, apply, or push managed
dotfiles.

`sync` never changes `$HOME` in the default `APPLY_MODE=manual` mode. It pulls
remote fast-forward changes, stages them, and pushes local commits created by
`store`. It rejects
dirty checkouts and non-fast-forward updates, copies tracked files from the
repository root into a revision-specific pending snapshot, and validates the
staged files before deployment. The path below that root is relative to `$HOME`;
for example, `.config/opencode/` deploys to `~/.config/opencode/`.

`apply` validates again, creates a rollback-capable backup, writes temporary
files, and then renames them into place. State and logs are stored under:

```text
~/.local/state/dotfiles-sync/
```

### After-Apply Hook

When a tracked `.config/dotfiles-sync/after-apply` file is present, `apply`
validates it with `sh -n`, deploys it with the revision, records the revision as
applied, and then runs the deployed version with `sh`. This permits a newer
configuration script to run only after it has been applied. The hook receives
`DOTFILES_SYNC_REPO_DIR` and `DOTFILES_SYNC_REVISION` in its environment.

The hook is absent by default and is never run by `sync`, `check`, or
`self-update`. It may intentionally change `$HOME`, so keep it small and
idempotent. Disable the conventional hook path by setting `AFTER_APPLY_HOOK=` in
`~/.config/dotfiles-sync/config`.

```sh
# Store the script as a managed dotfile.
dotfiles-sync store ~/.config/dotfiles-sync/after-apply
```

### Storing Local Changes

Use `store` to copy one or more files, or a directory, from `$HOME` into the
repository root. Absolute paths are accepted directly; relative paths
are resolved from the current directory but must still resolve inside `$HOME`.

```sh
dotfiles-sync store ~/.config/opencode/opencode.json
dotfiles-sync store ~/.bashrc ~/.zshrc
dotfiles-sync store ~/.config/opencode/
```

Existing files require an interactive overwrite confirmation. Non-interactive
runs optimistically proceed when no overwrite is needed. If an overwrite would
be required, they stop before changing anything and print a signature. Rerun
with that signature to prove the overwrite was reviewed. `--overwrite` is not a
supported option. Commit messages are prompted by default, or can be
supplied/generated:

```sh
dotfiles-sync store --message "Update OpenCode configuration" FILE...
dotfiles-sync store --auto-message FILE...
```

For an explicit preview, use:

```sh
dotfiles-sync store --dry-run --non-interactive --auto-message FILE...
dotfiles-sync store --non-interactive --confirm-overwrite SIGNATURE \
  --auto-message FILE...
```

The first command prints `OVERWRITE_TOKEN=...` when replacement is needed. The
second command must provide that exact token. This two-stage flow is intended
for agents and other non-interactive callers.

`store` requires a clean repository checkout and commits only changes under
the repository root. It does not push by itself; the next `dotfiles-sync sync` can push the
commit after it has been reviewed.

### Removing Managed Files

Use `remove` to delete a tracked regular file from the managed repository while
retaining the original file in `$HOME`:

```sh
dotfiles-sync remove ~/.config/opencode/obsolete.json
```

Use `--remove-original` to remove the matching `$HOME` file only after the
repository removal commits. That operation backs up the original and requires an
interactive confirmation or a dry-run token in non-interactive mode:

```sh
dotfiles-sync remove --dry-run --non-interactive --remove-original ~/.config/opencode/obsolete.json
dotfiles-sync remove --non-interactive --confirm-remove TOKEN --remove-original \
  --auto-message ~/.config/opencode/obsolete.json
```

`remove` accepts files only, requires paths under `$HOME`, and refuses untracked
paths. Like `store`, it does not push by itself.

Set `APPLY_MODE=automatic` to apply validated updates during polling. The
default `manual` mode is recommended until the workflow is trusted. `prompt`
is reserved for integrations that want to notify a user after staging.

## Installation

Run the installer from an extracted release archive or repository checkout. On
first installation, provide the dotfiles repository URL. Add `--branch NAME` to
use a branch other than the remote default:

```sh
bin/dotfiles-sync install --remote git@github.com:YOUR_USER/dotfiles.git
```

When run from a terminal, `install` prompts for the repository URL if `--remote`
is omitted. Non-interactive installation requires `--remote`.

It creates `~/.config/dotfiles-sync/config` when needed, deploys the CLI to
`~/.local/share/dotfiles-sync`, installs `~/.local/bin/dotfiles-sync`, and
registers the best available user scheduler. It does not require root
privileges. It is safe to rerun to repair the installation after a path or
scheduler change; use `dotfiles-sync self-update` to retrieve a newer release.

### Uninstallation

`dotfiles-sync uninstall` disables the scheduler and removes the deployed CLI,
command wrapper, and runtime state. It asks whether to remove
`~/.config/dotfiles-sync/`; choose `--keep-config` or `--remove-config` to skip
that question. Non-interactive uninstalls keep configuration unless
`--remove-config` is provided.

The tracked configuration example is:

```text
.config/dotfiles-sync/config.example
```

Configure `REMOTE`, `BRANCH`, `POLL_INTERVAL`, `APPLY_MODE`, `IGNORE_FILE`,
and `AFTER_APPLY_HOOK`. `IGNORE_FILE` and a non-empty `AFTER_APPLY_HOOK` must
be absolute paths; the hook must be under `$HOME`. The dotfiles checkout is
always `dotfiles/` below the deployed tool directory; do not
put secrets or machine-specific files in it.

For compatibility, the legacy relative conventional hook path is normalized in
memory until migration `v0.1.3` can rewrite it as an absolute path.

### Ignored Paths

`~/.config/dotfiles-sync/ignore` contains positive Gitignore-style patterns for
paths under the repository root that must never be staged or applied by the updater. It supports comments,
blank lines, and shell-style `*` globs. Negation rules beginning with `!` are
intentionally unsupported.

Every ignored pattern should also be present in the managed dotfiles
repository's `.gitignore`. This keeps machine-local files out of Git and means
the updater never receives them from a remote checkout. The updater reads
`IGNORE_FILE`, defaulting to `~/.config/dotfiles-sync/ignore`.

## Releases

Pushing a version tag such as `v1.0.0` creates a GitHub Release with a
`dotfiles-sync.tgz` asset. The archive contains an explicit allowlist of the
CLI, release metadata, configuration examples, migration scripts, scheduler
templates, and README at that tag. It can be downloaded and extracted on a new
machine before running `bin/dotfiles-sync install --remote ...`.

Every release keeps its own `dotfiles-sync.tgz` asset. GitHub's latest-release
marker changes only when the tag is greater than the current latest version
using numeric major, minor, and patch ordering.

Each release description is a changelog generated from Conventional Commit
subjects between the preceding tag and the release tag.

### Breaking Updates

When an updater release requires a breaking runtime configuration or state
change, add a POSIX migration script at
`.config/dotfiles-sync/migrations/vMAJOR.MINOR.PATCH.sh`. The script may modify
only dotfiles-sync runtime configuration and state, must be idempotent, and must
pass `sh -n`. It receives absolute `DOTFILES_SYNC_CONFIG_FILE`,
`DOTFILES_SYNC_CONFIG_DIR`, and `DOTFILES_SYNC_STATE_DIR` environment variables.

`self-update` validates and runs unrecorded migrations from each downloaded
release before deploying that release. It backs up the runtime configuration and
aborts the update if a migration fails. Authenticated GitHub CLI updates move
through intermediate releases when the latest release is more than two major
versions ahead. The workflow retains the two newest migration scripts and opens
cleanup pull requests for older ones on `main` and the matching `release/*`
branch.

The first `v1` tag creates a `release/v1` maintenance branch. The first `v1.2`
or `v1.2.3` tag similarly creates a `release/v1.2` branch. Later tags leave an
existing maintenance branch unchanged so patch fixes can be delivered from that
branch. The `release/*` namespace is reserved for maintenance branches and can
be used by workflow triggers and branch-protection rules.

The tag that creates a maintenance branch must be reachable from `main`. Later
patch tags, such as `v1.2.1`, must already be reachable from their maintenance
branch (`release/v1.2`); the workflow rejects patch releases cut from `main`.

### Backports

Implement fixes on `main` first. To request an intentional backport after the
commit reaches `main`, include this Conventional Commit trailer in the commit
body:

```text
Backport-To: release/v1
```

The backport workflow cherry-picks that commit onto an automation branch and
opens a pull request targeting the requested maintenance branch. Use the trailer
only for compatible maintenance fixes; it must not be used to automatically
backport all `main` changes.

`install` deploys the CLI under `~/.local/share/dotfiles-sync` and places a
wrapper at `~/.local/bin/dotfiles-sync`. Existing installations update through
`dotfiles-sync self-update`, which downloads the stable release archive over
HTTPS, validates it, and atomically replaces only that deployed CLI directory.
It never updates a Git checkout or the configured dotfiles repository.

For a private repository, authenticate the GitHub CLI with access to the
repository (`gh auth login`) or supply `GH_TOKEN` at update time. `self-update`
uses those credentials through `gh release download`; no token is stored in the
tool configuration. Public releases use the HTTPS downloader without GitHub CLI
authentication.

When `install` reuses an existing runtime configuration, it prints a warning and
does not replace that configuration.

## Commit Messages

Use Conventional Commits for every change that will be committed:

```text
type(optional-scope): short imperative description
```

Use `feat` for user-facing functionality, `fix` for bug fixes, `docs` for
documentation, `ci` for workflows, `test` for tests, `refactor` for behavior-
preserving code changes, and `chore` for maintenance. Mark breaking changes with
`!` after the type or scope and explain them in the commit body. These messages
and pull request titles feed the generated release changelog.

## Testing

Run the isolated updater suite before submitting updater changes:

```sh
sh tests/test_dotfiles_sync.sh
```

It validates command help, installation, storing, removal with and without the
original file, and the manual `sync` then `apply` lifecycle. GitHub Actions runs
the same suite for pull requests and pushes to `main` or `release/*`. Extend the
suite whenever updater behavior changes.

### Linux and WSL

With a working systemd user session, the installer enables
`dotfiles-sync.timer`. It runs two minutes after boot/login and then every six
hours.

On WSL without systemd, and on minimal Linux environments, it uses the user's
crontab when available. If cron is unavailable, it starts a background daemon.
That fallback must be restarted after the environment stops.

### Containers and Codespaces

Containers and GitHub Codespaces generally do not provide a persistent user
service. The installer uses cron or the background fallback when available.
For automatic reinstallation after recreation, invoke the installer from a
dev-container `postCreateCommand` or startup command.

### macOS

The installer creates and loads a launchd user agent that runs at load and then
every six hours.

## AI Workspace Support

The repository includes project instructions for multiple coding tools:

```text
AGENTS.md                         Shared workspace rules
.agents/skills/                   Codex project skills
.opencode/agents/                 OpenCode workspace agents
.opencode/skills/                 OpenCode skills
.github/copilot-instructions.md  GitHub Copilot instructions
.github/instructions/             GitHub Copilot scoped instructions
```

The shared rules cover safe deployment, shell portability, secrets handling,
the staged update lifecycle, and keeping the tool-specific instructions
aligned.
