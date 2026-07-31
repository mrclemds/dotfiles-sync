#!/bin/sh
# Convert the conventional legacy hook path to its required absolute form.

set -eu

config=$DOTFILES_SYNC_CONFIG_FILE
temporary=$config.dotfiles-sync-migration.$$

[ -r "$config" ] || exit 0

awk -v home="$HOME" '
    /^AFTER_APPLY_HOOK=\.config\/dotfiles-sync\/after-apply$/ {
        print "AFTER_APPLY_HOOK=" home "/.config/dotfiles-sync/after-apply"
        next
    }
    { print }
' "$config" > "$temporary"
mv "$temporary" "$config"
