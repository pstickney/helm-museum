#!/usr/bin/env bash

set -euo pipefail

if [ "$HELM_DEBUG" == true ]; then
  set -x

  env | grep "HELM_"
  echo "museum.sh '$*'"
fi
