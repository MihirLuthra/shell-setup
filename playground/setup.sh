#!/bin/bash

set -eo pipefail

readonly SCRIPT_DIR="$(dirname "$(realpath "$BASH_SOURCE")")"

if [ -z "$PLAYGROUND_DIR" ]
then
    echo_err "PLAYGROUND_DIR needs to be set to source playground.sh"
    return 1
fi

if [ -d "$PLAYGROUND_DIR" ]
then
    echo_err "$PLAYGROUND_DIR already exists. This script expects it to not be there"
    return 1
fi

mkdir -p "$PLAYGROUND_DIR"

cp -r "$SCRIPT_DIR"/playground-base/* "$PLAYGROUND_DIR"

echo "Setup done. Please set PLAYGROUND_DIR in your rc file."
