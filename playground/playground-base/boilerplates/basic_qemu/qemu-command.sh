#!/bin/bash

set -ex

SCRIPT_DIR="$(dirname "$(realpath "$BASH_SOURCE")")"
DISK="$SCRIPT_DIR/disk.qcow2"
UBUNTU_SERVER_ISO_FILE="$SCRIPT_DIR/../../read-only-data/qemu/iso/ubuntu-24.04.1-live-server-amd64.iso"
UBUNTU_DESKTOP_ISO_FILE="../../read-only-data/qemu/iso/ubuntu-24.04.1-desktop-amd64.iso"
ISO_FILE=

qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 2 \
    -cpu host \
    -drive file="$DISK",format=qcow2,id=disk0 \
    -cdrom "$ISO_FILE" \
    -boot d \
    -nographic \
    -serial file:output.log \
    -machine q35 -netdev user,id=mynet0 -device virtio-net-pci,netdev=mynet0,bus=pcie.0,addr=0x3
