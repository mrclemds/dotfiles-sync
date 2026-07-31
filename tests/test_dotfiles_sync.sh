#!/bin/sh

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-sync-test.XXXXXX")
trap 'rm -rf "$TEST_DIR"' 0 1 2 3 15

HOME=$TEST_DIR/home
export HOME
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME
GIT_CONFIG_GLOBAL=$TEST_DIR/gitconfig
export GIT_CONFIG_GLOBAL

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

# shellcheck source=.github/scripts/release-version.sh
. "$ROOT/.github/scripts/release-version.sh"
[ "$(release_version v1.2.3)" = 1.2.3 ] || fail "release version parsing failed"
[ "$(minor_release_version v1.2)" = 1.2 ] || fail "minor release version parsing failed"
if minor_release_version v1.2.3 >/dev/null; then
    fail "patch version accepted as minor release"
fi
release_version_is_greater v1.2 v1.1 || fail "release version ordering failed"

assert_file() { [ -f "$1" ] || fail "expected file: $1"; }
assert_missing() { [ ! -e "$1" ] || fail "expected missing path: $1"; }
assert_contains() { grep -F -- "$2" "$1" >/dev/null || fail "expected $2 in $1"; }

mkdir -p "$TEST_DIR/tool/bin" "$TEST_DIR/tool/.config/dotfiles-sync" \
    "$TEST_DIR/tool/systemd" "$TEST_DIR/bin" "$TEST_DIR/seed" "$TEST_DIR/remote.git"
cp "$ROOT/bin/dotfiles-sync" "$TEST_DIR/tool/bin/dotfiles-sync"
cp "$ROOT/.release-url" "$TEST_DIR/tool/.release-url"
cp "$ROOT/.config/dotfiles-sync/ignore.example" "$TEST_DIR/tool/.config/dotfiles-sync/ignore.example"
cp "$ROOT/systemd/dotfiles-sync.service" "$TEST_DIR/tool/systemd/dotfiles-sync.service"
cp "$ROOT/systemd/dotfiles-sync.timer" "$TEST_DIR/tool/systemd/dotfiles-sync.timer"
chmod 755 "$TEST_DIR/tool/bin/dotfiles-sync"

cat > "$TEST_DIR/bin/systemctl" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TEST_DIR/bin/crontab" <<'EOF'
#!/bin/sh
case "${1:-}" in
    -l) exit 1 ;;
    -) cat >/dev/null ;;
esac
EOF
chmod 755 "$TEST_DIR/bin/systemctl" "$TEST_DIR/bin/crontab"
PATH=$TEST_DIR/bin:$PATH
export PATH

git config --file "$GIT_CONFIG_GLOBAL" user.name DotfilesSyncTest
git config --file "$GIT_CONFIG_GLOBAL" user.email dotfiles-sync-test@example.invalid
mkdir -p "$TEST_DIR/release"
printf '%s\n' v1.1.1 > "$TEST_DIR/release/.release-version"
sed -n '/^release_version_is_valid()/,/^}/p' "$ROOT/bin/dotfiles-sync" > "$TEST_DIR/version-functions"
sed -n '/^release_directory_version()/,/^}/p' "$ROOT/bin/dotfiles-sync" >> "$TEST_DIR/version-functions"
# shellcheck source=/dev/null
. "$TEST_DIR/version-functions"
[ "$(release_directory_version "$TEST_DIR/release")" = v1.1.1 ] \
    || fail "release version marker lost its v prefix"
candidate=v1.1.1
release_version_is_valid "$candidate" || fail "release version was rejected"
[ "$candidate" = v1.1.1 ] || fail "release version validation mutated the caller"
git init --bare --initial-branch=main "$TEST_DIR/remote.git" >/dev/null
git init --initial-branch=main "$TEST_DIR/seed" >/dev/null
printf 'one\n' > "$TEST_DIR/seed/managed.txt"
git -C "$TEST_DIR/seed" add managed.txt
git -C "$TEST_DIR/seed" commit -m "test: initialize managed file" >/dev/null
git -C "$TEST_DIR/seed" remote add origin "$TEST_DIR/remote.git"
git -C "$TEST_DIR/seed" push origin main >/dev/null

"$TEST_DIR/tool/bin/dotfiles-sync" install --remote "$TEST_DIR/remote.git" --branch main >/dev/null
assert_file "$HOME/.local/bin/dotfiles-sync"
assert_file "$XDG_CONFIG_HOME/dotfiles-sync/config"
# The runtime config must retain this expression for the updater to expand.
# shellcheck disable=SC2016
printf '%s\n' 'IGNORE_FILE="${HOME:-/test}/.config/dotfiles-sync/ignore"' \
    >> "$XDG_CONFIG_HOME/dotfiles-sync/config"
printf 'one\n' > "$HOME/managed.txt"
"$HOME/.local/bin/dotfiles-sync" help store > "$TEST_DIR/store-help"
assert_contains "$TEST_DIR/store-help" 'Usage: dotfiles-sync store [OPTIONS] PATH...'
"$HOME/.local/bin/dotfiles-sync" remove --help > "$TEST_DIR/remove-help"
assert_contains "$TEST_DIR/remove-help" --remove-original

printf 'stored\n' > "$HOME/store.txt"
if "$HOME/.local/bin/dotfiles-sync" store --non-interactive --auto-message "$HOME/store.txt" >/dev/null 2>&1; then
    fail "non-interactive store accepted --auto-message"
fi
"$HOME/.local/bin/dotfiles-sync" store --non-interactive --message "test: store file" "$HOME/store.txt" >/dev/null
assert_file "$XDG_DATA_HOME/dotfiles-sync/dotfiles/store.txt"

"$HOME/.local/bin/dotfiles-sync" remove --non-interactive --message "test: remove file" "$HOME/store.txt" >/dev/null
assert_file "$HOME/store.txt"
assert_missing "$XDG_DATA_HOME/dotfiles-sync/dotfiles/store.txt"
git -C "$XDG_DATA_HOME/dotfiles-sync/dotfiles" reset --hard origin/main >/dev/null

"$HOME/.local/bin/dotfiles-sync" remove --dry-run --non-interactive --remove-original "$HOME/managed.txt" \
    > "$TEST_DIR/remove-dry-run"
token=$(sed -n 's/^REMOVE_TOKEN=//p' "$TEST_DIR/remove-dry-run")
[ -n "$token" ] || fail "missing removal token"
"$HOME/.local/bin/dotfiles-sync" remove --non-interactive --message "test: remove original" --remove-original \
    --confirm-remove "$token" "$HOME/managed.txt" >/dev/null
assert_missing "$HOME/managed.txt"
assert_file "$XDG_STATE_HOME/dotfiles-sync/backups/removals"/*/managed.txt
git -C "$XDG_DATA_HOME/dotfiles-sync/dotfiles" reset --hard origin/main >/dev/null

printf 'two\n' > "$TEST_DIR/seed/managed.txt"
git -C "$TEST_DIR/seed" add managed.txt
git -C "$TEST_DIR/seed" commit -m "test: update managed file" >/dev/null
git -C "$TEST_DIR/seed" push origin main >/dev/null
"$HOME/.local/bin/dotfiles-sync" sync >/dev/null
"$HOME/.local/bin/dotfiles-sync" apply >/dev/null
assert_file "$HOME/managed.txt"
assert_contains "$HOME/managed.txt" two

printf '%s\n' 'dotfiles-sync tests passed'
