#!/usr/bin/env bash
# Simulates the CD half of a CI pipeline: change desired state in Git, commit, push.
# Argo CD (pull-based) picks it up on its next poll; Argo Rollouts does the progressive part.
#
#   usage: scripts/release.sh <app> <image-tag> <message> [good|bad|slow]
#     good  normal release
#     bad   ~1/3 of requests fail (PODINFO_RANDOM_ERROR=true)
#     slow  every request takes 0.8-1.5s (PODINFO_RANDOM_DELAY=true)
#   (message: no "/" or quotes)
set -euo pipefail

usage() { sed -n '2,10p' "$0"; exit 1; }
[[ $# -ge 3 ]] || usage
APP=$1 TAG=$2 MSG=$3 MODE=${4:-good}

cd "$(git rev-parse --show-toplevel)"
FILE="apps/${APP}/rollout.yaml"
[[ -f $FILE ]] || { echo "no such file: $FILE" >&2; exit 1; }

case $MODE in
  good) ERR=false; DELAY=false ;;
  bad)  ERR=true;  DELAY=false ;;
  slow) ERR=false; DELAY=true  ;;
  *) usage ;;
esac

# set the "value:" line that follows "- name: <ENV>"
set_env() { sed -i -E "/- name: $1\$/{n;s/(value: ).*/\1\"$2\"/}" "$FILE"; }

sed -i -E "s#(image: ghcr\.io/stefanprodan/podinfo:)[^[:space:]]+#\1${TAG}#" "$FILE"
set_env PODINFO_UI_MESSAGE   "$MSG"
set_env PODINFO_RANDOM_ERROR "$ERR"
set_env PODINFO_RANDOM_DELAY "$DELAY"

git --no-pager diff --stat -- "$FILE"
if git diff --quiet -- "$FILE"; then echo "nothing changed"; exit 0; fi

git add "$FILE"
git commit -q -m "release(${APP}): podinfo ${TAG} \"${MSG}\" [${MODE}]"
git push -q
git --no-pager log -1 --oneline
echo "pushed. Argo CD will pick it up within ~60s (or: argocd app get ${APP} --refresh)"
