#!/usr/bin/env bash

set -euo pipefail

CHARTMUSEUM_VERSION="0.12.0"
CHARTMUSEUM_DARWIN_SHA="33363f7471968a983d3f52562398fb120cc9022595ce5d090a5870d34ec45088"
CHARTMUSEUM_LINUX_SHA="53402edf5ac9f736cb6da8f270f6bbf356dcbbe5592d8a09ee6f91a2dc30e4f6"

get_url () {
  echo "https://s3.amazonaws.com/chartmuseum/release/v$1/bin/$2/amd64/chartmuseum"
}

get_sha () {
  if command -v sha256sum > /dev/null; then sha=$(sha256sum "$1")
  elif command -v shasum > /dev/null; then sha=$(shasum -a 256 "$1")
  else sha="error"
  fi
  echo $sha | cut -d ' ' -f 1
}

env
echo "install-binary.sh '$*'"

if [ -f "$HELM_PLUGIN_DIR/chartmuseum" ]; then
  "$HELM_PLUGIN_DIR/chartmuseum" --version
else
  if [ "$(uname)" == "Darwin" ]; then
    curl --progress-bar -SL "$(get_url CHARTMUSEUM_VERSION "darwin")" > "$HELM_PLUGIN_DIR/chartmuseum"
  elif [ "$(uname)" == "Linux" ]; then
    curl --progress-bar -SL "$(get_url CHARTMUSEUM_VERSION "linux")" > "$HELM_PLUGIN_DIR/chartmuseum"
  else
    echo "No package available"
    exit 1
  fi
  chmod +x "$HELM_PLUGIN_DIR/chartmuseum"
  echo "chartmuseum installed"
fi
