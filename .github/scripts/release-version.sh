#!/bin/sh

release_version() {
    value=${1#v}
    case "$value" in
        ''|.*|*..*|*.|*.*.*.*|*[!0-9.]*) return 1 ;;
    esac
    printf '%s\n' "$value"
}

minor_release_version() {
    value=$(release_version "$1") || return 1
    case "$value" in
        *.*.*) return 1 ;;
        *.*) ;;
        *) return 1 ;;
    esac
    printf '%s\n' "$value"
}

release_version_parts() {
    value=$(release_version "$1") || return 1
    major=${value%%.*}
    remainder=${value#*.}
    if [ "$remainder" = "$value" ]; then
        printf '%s 0 0\n' "$major"
        return
    fi
    minor=${remainder%%.*}
    patch=${remainder#*.}
    if [ "$patch" = "$remainder" ]; then
        patch=0
    fi
    printf '%s %s %s\n' "$major" "$minor" "$patch"
}

release_version_is_greater() {
    candidate=$1
    current=$2
    candidate_parts=$(release_version_parts "$candidate") || return 1
    current_parts=$(release_version_parts "$current") || return 1
    IFS=' ' read -r candidate_major candidate_minor candidate_patch <<EOF
$candidate_parts
EOF
    IFS=' ' read -r current_major current_minor current_patch <<EOF
$current_parts
EOF
    [ "$candidate_major" -gt "$current_major" ] && return 0
    [ "$candidate_major" -lt "$current_major" ] && return 1
    [ "$candidate_minor" -gt "$current_minor" ] && return 0
    [ "$candidate_minor" -lt "$current_minor" ] && return 1
    [ "$candidate_patch" -gt "$current_patch" ]
}
