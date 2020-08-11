#!/usr/bin/env bash

set -euo pipefail

if [ "$HELM_DEBUG" == true ]; then
  set -x

  env | grep "HELM_"
  echo "hooks.sh '$*'"
fi

SCRIPT="$0"
HOOK="$1"
HELM_MUSEUM_GIT_URL="https://github.com/pstickney/helm-museum.git"
CHARTMUSEUM_DARWIN_SHA="33363f7471968a983d3f52562398fb120cc9022595ce5d090a5870d34ec45088"
CHARTMUSEUM_LINUX_SHA="53402edf5ac9f736cb6da8f270f6bbf356dcbbe5592d8a09ee6f91a2dc30e4f6"

get_url () {
  echo "https://s3.amazonaws.com/chartmuseum/release/v$1/bin/$2/amd64/chartmuseum"
}

get_sha () {
  local sha=""
  local file="$1"
  if command -v sha256sum > /dev/null; then
    sha=$(sha256sum "$file")
  elif command -v shasum > /dev/null; then
    sha=$(shasum -a 256 "$file")
  else
    echo "SHA256 utility not found."
    exit 1
  fi
  echo "$sha" | cut -d ' ' -f 1
}

download () {
  local url="$1"
  local file="$2"
  if command -v curl > /dev/null; then
    curl --progress-bar -SL "$url" > "$file"
  elif command -v wget > /dev/null; then
    wget -q --show-progress --progress=bar:force:noscroll "$url" -O "$file"
  else
    echo "Download utility not found. Get curl or wget"
    exit 1
  fi
}

git_latest_tag () {
  if command -v git > /dev/null; then
    git describe --tags "$(git rev-list --tags --max-count=1)"
  else
    echo "Git utility not found."
    exit 1
  fi
}

get_plugin_version () {
  if [ -f "plugin.yaml" ]; then
    grep "version" "plugin.yaml" | cut -d '"' -f 2
  else
    echo "Plugin version unavailable."
    exit 1
  fi
}

get_chartmuseum_binary_version () {
  if [ -f "chartmuseum" ]; then
    chartmuseum --version | cut -d ' ' -f 3
  else
    echo "Chartmuseum version unavailable."
    exit 1
  fi
}

get_chartmuseum_target_version () {
  if [ -f "CHARTMUSEUM_VERSION" ]; then
    cat "CHARTMUSEUM_VERSION"
  else
    echo "Target version unavailable."
    exit 1
  fi
}

plugin_update_available () {
  local plugin_version="$(get_plugin_version)"
  local latest_version="$(git_latest_tag)"
  [ "$plugin_version" != "$latest_version" ]
}

plugin_update () {
  if command -v git > /dev/null; then
    local tmpDir="$(mktemp -d)"
    local latestTag="$(git_latest_tag)"
    pushd "$tmpDir"
    git clone "$HELM_MUSEUM_GIT_URL" .
    git checkout -b latest "$latestTag"
    cp ./* "$HELM_PLUGIN_DIR/"
    popd
    rm -rf "$tmpDir"
  else
    echo "Git utility not found."
    exit 1
  fi
}

chartmuseum_update_available () {
  local installed="false"
  local chartmuseum_version="$(get_chartmuseum_binary_version)"
  local target_version="$(get_chartmuseum_target_version)"
  if [ -f "chartmuseum" ]; then
    installed="true"
  fi
  [ "$installed" != "true" ] || [ "$chartmuseum_version" != "$target_version" ]
}

chartmuseum_update () {
  local version="$(get_chartmuseum_target_version)"
  if [ "$(uname)" == "Darwin" ]; then
    download "$(get_url "$version" "darwin")" "chartmuseum"
  elif [ "$(uname)" == "Linux" ]; then
    download "$(get_url "$version" "linux")" "chartmuseum"
  else
    echo "Platform not supported."
    exit 1
  fi
}

validate () {
  if [ -f "chartmuseum" ]; then
    if [ "$(uname)" == "Darwin" ]; then
      [ "$(get_sha "chartmuseum")" != "${CHARTMUSEUM_DARWIN_SHA}" ]
    elif [ "$(uname)" == "Linux" ]; then
      [ "$(get_sha "chartmuseum")" != "${CHARTMUSEUM_LINUX_SHA}" ]
    else
      echo "Platform not supported."
      exit 1
    fi
  else
    return 1
  fi
}

set_execute () {
  chmod +x "chartmuseum"
}

main () {
  if chartmuseum_update_available; then
    chartmuseum_update
    if validate; then
      set_execute
    fi
  fi
}

if plugin_update_available; then
  plugin_update
  $SCRIPT "$HOOK"
  exit 0
fi

main
