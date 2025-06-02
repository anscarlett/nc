#!/usr/bin/env bash

set -e

# Configuration
VM_NAME="nixos-test"
RAM_SIZE="4G"
DISK_SIZE="40G"
CPU_CORES="2"
ISO_URL="https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso"
DISK_IMAGE="$VM_NAME.qcow2"

# Create directory for VM files if it doesn't exist
mkdir -p vm-data

# Download the ISO if it doesn't exist
if [ ! -f "vm-data/nixos-installer.iso" ]; then
    echo "Downloading NixOS 25.05 installer ISO..."
    curl -L "$ISO_URL" -o "vm-data/nixos-installer.iso"
fi

# Create a disk image if it doesn't exist
if [ ! -f "vm-data/$DISK_IMAGE" ]; then
    echo "Creating virtual disk image..."
    qemu-img create -f qcow2 "vm-data/$DISK_IMAGE" "$DISK_SIZE"
fi

echo "Starting VM with NixOS installer..."
qemu-system-x86_64 \
    -name "$VM_NAME" \
    -enable-kvm \
    -cpu host \
    -smp "$CPU_CORES" \
    -m "$RAM_SIZE" \
    -boot d \
    -drive file="vm-data/$DISK_IMAGE",if=virtio \
    -cdrom "vm-data/nixos-installer.iso" \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0 \
    -vga virtio \
    -display gtk,gl=on \
    -usb \
    -device usb-tablet
