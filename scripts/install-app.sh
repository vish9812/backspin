#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${BACKSPIN_INSTALL_DIR:-$HOME/Applications}"
APP="$DESTINATION/backspin.app"

if pgrep -x backspin >/dev/null; then
    printf 'Quit backspin from its menu before installing, then run just install again.\n' >&2
    exit 1
else
    PROCESS_STATUS=$?
    if [[ "$PROCESS_STATUS" -ne 1 ]]; then
        printf 'Could not check whether backspin is running; installation stopped.\n' >&2
        exit 1
    fi
fi

bash "$ROOT/scripts/build-app.sh"
mkdir -p "$DESTINATION"
if [[ -e "$APP" || -L "$APP" ]]; then
    if [[ -L "$APP" || ! -d "$APP" ]] ||
       [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist" 2>/dev/null || true)" != 'local.backspin' ]]; then
        printf 'Refusing to replace an unrelated app at %s\n' "$APP" >&2
        exit 1
    fi
fi

STAGING="$(mktemp -d "$DESTINATION/.backspin-install.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
ditto "$ROOT/.build/backspin.app" "$STAGING/backspin.app"
codesign --verify --strict "$STAGING/backspin.app"
if [[ -d "$APP" ]]; then
    mv "$APP" "$STAGING/previous.app"
fi
if ! mv "$STAGING/backspin.app" "$APP"; then
    if [[ -d "$STAGING/previous.app" ]]; then
        if ! mv "$STAGING/previous.app" "$APP"; then
            trap - EXIT
            printf 'Could not restore the previous app; it is saved at %s\n' "$STAGING/previous.app" >&2
        fi
    fi
    exit 1
fi
printf '\nInstalled %s\nOpen it with: open "%s"\n' "$APP" "$APP"
