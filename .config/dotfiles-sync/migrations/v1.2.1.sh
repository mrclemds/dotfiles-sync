#!/bin/sh
# Rename generic automatic mode settings to their command-specific names.

set -eu

config=$DOTFILES_SYNC_CONFIG_FILE
temporary=$config.dotfiles-sync-migration.$$

[ -r "$config" ] || exit 0

sync_apply_mode_exists=no
store_push_mode_exists=no
grep -q '^SYNC_APPLY_MODE=' "$config" && sync_apply_mode_exists=yes || true
grep -q '^STORE_PUSH_MODE=' "$config" && store_push_mode_exists=yes || true

awk -v sync_apply_mode_exists="$sync_apply_mode_exists" \
    -v store_push_mode_exists="$store_push_mode_exists" '
    /^APPLY_MODE=/ {
        if (sync_apply_mode_exists == "no") {
            sub(/^APPLY_MODE=/, "SYNC_APPLY_MODE=")
            print
        }
        next
    }
    /^PUSH_MODE=/ {
        if (store_push_mode_exists == "no") {
            sub(/^PUSH_MODE=/, "STORE_PUSH_MODE=")
            print
        }
        next
    }
    { print }
' "$config" > "$temporary"
mv "$temporary" "$config"
