#!/usr/bin/env bash
# usage: scripts/sample.sh <namespace> [url] [count] [extra curl args...]
# Sends <count> requests from inside the cluster and histograms the "message" field.
set -euo pipefail
NS=$1; URL=${2:-http://podinfo}; N=${3:-100}; shift $(( $# < 3 ? $# : 3 ))
EXTRA="$*"
kubectl -n "$NS" run "sampler-$RANDOM" --rm -i --restart=Never --quiet \
  --image=curlimages/curl:8.17.0 --command -- sh -c "
    for i in \$(seq $N); do
      curl -s --max-time 5 $EXTRA $URL/ | grep -o '\"message\": *\"[^\"]*\"' || echo 'ERROR/non-200'
    done | sort | uniq -c"
