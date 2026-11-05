#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/backspin.app"
if [[ ! -x "$APP/Contents/MacOS/backspin" ]]; then
    bash "$ROOT/scripts/build-app.sh"
fi
open -g "$APP"
