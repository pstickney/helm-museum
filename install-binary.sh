#!/usr/bin/env bash

CHARTMUSEUM_VERSION="0.12.0"
CHARTMUSEUM_DARWIN_URL="https://s3.amazonaws.com/chartmuseum/release/v${CHARTMUSEUM_VERSION}/bin/darwin/amd64/chartmuseum"
CHARTMUSEUM_DARWIN_SHA="33363f7471968a983d3f52562398fb120cc9022595ce5d090a5870d34ec45088"
CHARTMUSEUM_LINUX_URL="https://s3.amazonaws.com/chartmuseum/release/v${CHARTMUSEUM_VERSION}/bin/linux/amd64/chartmuseum"
CHARTMUSEUM_LINUX_SHA="53402edf5ac9f736cb6da8f270f6bbf356dcbbe5592d8a09ee6f91a2dc30e4f6"

#if hash chartmuseum 2> /dev/null; then
#  echo "chartmuseum is already installed"
#  chartmuseum --version
#else
#  echo "chartmuseum is not installed"
#fi

echo "install-binary.sh '$*'"
