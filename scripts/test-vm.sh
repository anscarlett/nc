#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Testing NixOS configuration in VM"

CONFIG_NAME="${1:-vm-test}"
MEMORY="${2:-4096}"
CORES="${3:-2}"

echo "📦 Building NixOS configuration: $CONFIG_NAME"
nix --extra-experimental-features nix-command --extra-experimental-features flakes \
    build .#nixosConfigurations.$CONFIG_NAME.config.system.build.vm

echo "🖥️  Starting VM with $MEMORY MB RAM and $CORES CPU cores"
echo "Default login: adrian / root"
echo "SSH is enabled on port 2222 (forwarded from VM port 22)"
echo "To SSH: ssh -p 2222 adrian@localhost"
echo "To stop VM: Ctrl+C or shutdown from inside VM"
echo ""

VM_SCRIPT=$(find result/bin -name "run-*-vm" | head -1)

export QEMU_OPTS="-virtfs local,path=/home/adrianscarlett/projects,mount_tag=host_projects,security_model=none"

"$VM_SCRIPT" -m $MEMORY -smp $CORES