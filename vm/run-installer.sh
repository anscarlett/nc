#!/usr/bin/env bash

set -e

# Enable required Nix features
export NIX_CONFIG="experimental-features = nix-command flakes"

# Configuration
VM_NAME="nixos-test"
RAM_SIZE="4G"
DISK_SIZE="40G"
CPU_CORES="2"
ISO_URL="https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso"
DISK_IMAGE="$VM_NAME.qcow2"

# Create directory for VM files if it doesn't exist
mkdir -p vm-data

# Build our custom installer ISO if it doesn't exist
if [ ! -f "vm-data/nixos-installer.iso" ]; then
    echo "Building custom NixOS installer ISO..."
    nix shell nixpkgs#nixos-generators -c nixos-generate -f iso --flake .#installer -o vm-data/nixos-installer.iso
fi

# Create a disk image if it doesn't exist
if [ ! -f "vm-data/$DISK_IMAGE" ]; then
    echo "Creating virtual disk image..."
    qemu-img create -f qcow2 "vm-data/$DISK_IMAGE" "$DISK_SIZE"
fi

# Create mount script
cat > vm-data/mount-host.sh <<'EOL'
#!/bin/sh
mkdir -p /mnt/host
mount -t 9p -o trans=virtio,version=9p2000.L host /mnt/host
EOL

chmod +x vm-data/mount-host.sh

echo "Starting VM with NixOS installer..."
exec qemu-system-x86_64 \
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
    -device usb-tablet \
    -fsdev local,id=host,path=$(pwd),security_model=none \
    -device virtio-9p-pci,fsdev=host,mount_tag=host
