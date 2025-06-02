#!/usr/bin/env bash

set -e

# Mount the host directory to access our config
sudo mkdir -p /mnt/host
sudo mount -t 9p -o trans=virtio,version=9p2000.L host /mnt/host
cd /mnt/host

# Install using nixos-anywhere
sudo nix run github:nix-community/nixos-anywhere -- \
  --flake .#vm \
  --disk-encryption-keys "" \
  root@localhost

# Reboot after installation
sudo reboot
