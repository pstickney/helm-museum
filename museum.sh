#!/usr/bin/env bash

set -euox pipefail

env | grep "HELM_"
echo "museum.sh '$*'"
