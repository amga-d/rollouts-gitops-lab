#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_USER:?export GITHUB_USER first}"
cd "$(git rev-parse --show-toplevel)"
PH="YOUR_GH""_USER" # split so this script never matches (and rewrites) itself
grep -rl "$PH" --exclude-dir=.git . | xargs -r sed -i "s/$PH/$GITHUB_USER/g"
echo "placeholders replaced with $GITHUB_USER"
