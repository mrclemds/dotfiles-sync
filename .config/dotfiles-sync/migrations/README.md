# Runtime Migrations

Add a POSIX shell script named `vMAJOR.MINOR.PATCH.sh` when a release requires a
breaking runtime configuration or updater-state migration. Scripts receive these
absolute paths in their environment:

- `DOTFILES_SYNC_CONFIG_FILE`
- `DOTFILES_SYNC_CONFIG_DIR`
- `DOTFILES_SYNC_STATE_DIR`

Scripts may modify only dotfiles-sync runtime configuration and state. They must
be idempotent, validate with `sh -n`, and exit nonzero when migration cannot be
completed. The updater backs up the runtime configuration before running pending
migrations and records each successful script.

Release archives retain the two newest migration scripts. The release workflow
opens cleanup pull requests for older scripts; do not remove migrations manually.
