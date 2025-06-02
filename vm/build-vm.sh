#!/usr/bin/env bash

# Exit on error
set -e

# Get the hostname to test (default to 'vm')
HOST="${1:-vm}"

echo "Building VM configuration for host: $HOST..."

# Build the VM
nix build ".#nixosConfigurations.$HOST.config.system.build.vm" --show-trace

# Run the VM
./result/bin/run-*-vm
