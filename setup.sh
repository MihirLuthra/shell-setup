#!/bin/bash

set -eo pipefail

readonly SCRIPT_DIR="$(dirname "$(realpath "$BASH_SOURCE")")"

echo "Setting up playground"
pushd "$SCRIPT_DIR"/playground
bash -"$-" setup.sh
popd

