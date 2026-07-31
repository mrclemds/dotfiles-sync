# dotfiles-sync

This repository contains the POSIX shell updater for a Git-hosted dotfiles
repository. It stages changes and can optionally apply them to a user's home
directory.

## Repository Layout

```text
home/                            Empty placeholder for a managed dotfiles tree
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
and under `~/.config/dotfiles-sync/` at runtime. Add managed dotfiles below
`home/` only in a repository intended to distribute those files.

## Updater

`bin/dotfiles-sync` supports:

```text
install    Install or repair the command and register a user scheduler
self-update Fast-forward the CLI repository, then reinstall the command
store      Copy local HOME files into home/, then create a Git commit
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
bin/dotfiles-sync install
dotfiles-sync sync
dotfiles-sync status
dotfiles-sync apply
```

Use `dotfiles-sync --help` for the complete command reference, including
`store` options. `install` is idempotent: it refreshes the installed executable
and scheduler configuration. Use `dotfiles-sync self-update` to update the CLI from
the configured repository. It requires a clean checkout, fast-forwards only,
and does not stage, apply, or push managed dotfiles.

`sync` never changes `$HOME` in the default `APPLY_MODE=manual` mode. It pulls
remote fast-forward changes, stages them, and pushes local commits created by
`store`. It rejects
dirty checkouts and non-fast-forward updates, copies tracked files under
`home/` into a revision-specific pending snapshot, and validates the staged
files before deployment. The path below `home/` is the path relative to `$HOME`;
for example, `home/.config/opencode/` deploys to `~/.config/opencode/`.

`apply` validates again, creates a rollback-capable backup, writes temporary
files, and then renames them into place. State and logs are stored under:

```text
~/.local/state/dotfiles-sync/
```

### After-Apply Hook

When a tracked `home/.config/dotfiles-sync/after-apply` file is present, `apply`
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
repository's `home/` tree. Absolute paths are accepted directly; relative paths
are resolved from the current directory but must still resolve inside `$HOME`.

```sh
dotfiles-sync store ~/.config/opencode/opencode.json
dotfiles-sync store ~/.bashrc ~/.zshrc
dotfiles-sync store ~/.config/opencode/
dotfiles-sync store --list files-to-store.txt
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
`home/`. It does not push by itself; the next `dotfiles-sync sync` can push the
commit after it has been reviewed.

Set `APPLY_MODE=automatic` to apply validated updates during polling. The
default `manual` mode is recommended until the workflow is trusted. `prompt`
is reserved for integrations that want to notify a user after staging.

## Installation

Run the installer from the repository checkout:

```sh
bin/dotfiles-sync install
```

It creates `~/.config/dotfiles-sync/config` when needed, installs
`~/.local/bin/dotfiles-sync`, and registers the best available user scheduler.
It does not require root privileges. It is safe to rerun to repair the
installation after a path or scheduler change; use `dotfiles-sync self-update` to
retrieve a newer version from Git.

The tracked configuration example is:

```text
.config/dotfiles-sync/config.example
```

Configure `REPO_DIR`, `REMOTE`, `BRANCH`, `POLL_INTERVAL`, `APPLY_MODE`,
`DOTFILES_ROOT`, and `IGNORE_FILE`. The default managed root is `home/`; do not
put secrets or machine-specific files in it.

### Ignored Paths

`~/.config/dotfiles-sync/ignore` contains positive Gitignore-style patterns for
paths under `home/` that must never be staged or applied by the updater. It supports comments,
blank lines, and shell-style `*` globs. Negation rules beginning with `!` are
intentionally unsupported.

Every ignored pattern should also be present in the managed dotfiles
repository's `.gitignore`. This keeps machine-local files out of Git and means
the updater never receives them from a remote checkout. The updater reads
`IGNORE_FILE`, defaulting to `~/.config/dotfiles-sync/ignore`.

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
