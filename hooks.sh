#!/usr/bin/env bash

set -euo pipefail

if [ "$HELM_DEBUG" == true ]; then
  set -x
fi

CHARTMUSEUM_VERSION_URL="https://raw.githubusercontent.com/pstickney/helm-museum/master/CHARTMUSEUM_VERSION"
CHARTMUSEUM_DARWIN_SHA="33363f7471968a983d3f52562398fb120cc9022595ce5d090a5870d34ec45088"
CHARTMUSEUM_LINUX_SHA="53402edf5ac9f736cb6da8f270f6bbf356dcbbe5592d8a09ee6f91a2dc30e4f6"

get_url () {
  echo "https://s3.amazonaws.com/chartmuseum/release/v$1/bin/$2/amd64/chartmuseum"
}

get_sha () {
  local sha
  if command -v sha256sum > /dev/null; then
    sha=$(sha256sum "$1")
  elif command -v shasum > /dev/null; then
    sha=$(shasum -a 256 "$1")
  else
    sha="error"
  fi
  echo $sha | cut -d ' ' -f 1
}

download () {
  echo "Downloading..."
  if command -v curl > /dev/null; then
    curl --progress-bar -SL "$1" > "$2"
  elif command -v wget > /dev/null; then
    wget -q --show-progress --progress=bar:force:noscroll "$1" -O "$2"
  else
    echo "No download utility found. Get curl or wget"
    exit 1
  fi
}

cleanup () {
  echo "Cleaning..."
  if [ -f "$1" ]; then
    rm -f "$1"
  fi
}

env | grep "HELM_"
echo "hooks.sh '$*'"

# Get the chartmuseum version
TMP_VERSION="$(mktemp)"
CHARTMUSEUM_VERSION="0"
trap 'cleanup $TMP_VERSION' EXIT
if [ -f "$TMP_VERSION" ]; then
  download "$CHARTMUSEUM_VERSION_URL" "$TMP_VERSION"
  CHARTMUSEUM_VERSION="$(cat "$TMP_VERSION")"
else
  echo "Could not get version information"
  exit 1
fi

# Check to see if chartmuseum is already installed
INSTALLED="false"
VERSION="0"
if [ -f "$HELM_PLUGIN_DIR/chartmuseum" ]; then
  INSTALLED="true"
  VERSION="$("$HELM_PLUGIN_DIR/chartmuseum" --version | cut -d ' ' -f 3)"
fi

# Download chartmuseum binaries
if [ "$INSTALLED" != "true" ] || [ "$VERSION" != "$CHARTMUSEUM_VERSION" ]; then
  if [ "$(uname)" == "Darwin" ]; then
    download "$(get_url "$CHARTMUSEUM_VERSION" "darwin")" "$HELM_PLUGIN_DIR/chartmuseum"
  elif [ "$(uname)" == "Linux" ]; then
    download "$(get_url "$CHARTMUSEUM_VERSION" "linux")" "$HELM_PLUGIN_DIR/chartmuseum"
  else
    echo "No package available"
    exit 1
  fi
fi

# Compute chartmuseum SHA256
if [ -f "$HELM_PLUGIN_DIR/chartmuseum" ]; then
  if [ "$(uname)" == "Darwin" ]; then
    if [ "$(get_sha "$HELM_PLUGIN_DIR/chartmuseum")" != "${CHARTMUSEUM_DARWIN_SHA}" ]; then
      echo "Invalid computed SHA"
      exit 1
    fi
  elif [ "$(uname)" == "Linux" ]; then
    if [ "$(get_sha "$HELM_PLUGIN_DIR/chartmuseum")" != "${CHARTMUSEUM_LINUX_SHA}" ]; then
      echo "Invalid computed SHA"
      exit 1
    fi
  else
    echo "Cannot compute SHA"
    exit 1
  fi
  chmod +x "$HELM_PLUGIN_DIR/chartmuseum"
fi
