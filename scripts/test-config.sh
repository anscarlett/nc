#!/usr/bin/env bash
set -euo pipefail

# Quick VM functionality test
echo "🧪 Testing VM functionality..."

# Check if VM built successfully
if [[ ! -L result ]]; then
    echo "❌ VM build failed - no result symlink found"
    exit 1
fi

echo "✅ VM build successful"

# Check VM script exists
VM_SCRIPT=$(find result/bin -name "run-*-vm" | head -1)
if [[ ! -f "$VM_SCRIPT" ]]; then
    echo "❌ VM run script not found"
    exit 1
fi

echo "✅ VM run script found"

# Test configuration validity
echo "🔍 Testing configuration validity..."

# Test that all required modules are properly imported
nix --extra-experimental-features nix-command --extra-experimental-features flakes \
    eval .#nixosConfigurations.vm-test.config.system.nixos.version >/dev/null

echo "✅ Configuration evaluation successful"

# Test Home Manager integration
HM_USERS=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes \
    eval --json .#nixosConfigurations.vm-test.config.home-manager.users 2>/dev/null || echo "{}")

if echo "$HM_USERS" | grep -q "adrian"; then
    echo "✅ Home Manager integration working"
else
    echo "⚠️  Home Manager not configured for this host (this is OK for VM testing)"
fi

# Test that user is properly configured
USER_GROUPS=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes \
    eval --json .#nixosConfigurations.vm-test.config.users.users.adrian.extraGroups)

if echo "$USER_GROUPS" | grep -q "wheel"; then
    echo "✅ User adrian has wheel group access"
else
    echo "❌ User adrian missing wheel group"
    exit 1
fi

# Test SSH configuration
SSH_ENABLED=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes \
    eval .#nixosConfigurations.vm-test.config.services.openssh.enable)

if [[ "$SSH_ENABLED" == "true" ]]; then
    echo "✅ SSH service enabled"
else
    echo "❌ SSH service not enabled"
    exit 1
fi

# Test desktop environment
DE_ENABLED=$(nix --extra-experimental-features nix-command --extra-experimental-features flakes \
    eval .#nixosConfigurations.vm-test.config.services.xserver.enable)

if [[ "$DE_ENABLED" == "true" ]]; then
    echo "✅ Desktop environment enabled"
else
    echo "❌ Desktop environment not enabled"
    exit 1
fi

echo ""
echo "🎉 All tests passed! VM is ready for testing."
echo ""
echo "To start the VM run:"
echo "  ./scripts/test-vm.sh"
echo ""
echo "Or manually:"
echo "  $VM_SCRIPT"
