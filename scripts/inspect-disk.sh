#!/usr/bin/env bash

echo "=== NixOS Disk Layout Inspector ==="
echo

echo "1. Current filesystem mounts:"
findmnt --df
echo

echo "2. Block devices:"
lsblk -f
echo

echo "3. Disk usage:"
df -h
echo

echo "4. Partition table:"
sudo fdisk -l 2>/dev/null | head -20
echo

echo "5. NixOS configuration filesystems:"
nixos-option fileSystems 2>/dev/null || echo "nixos-option not available"
echo

echo "6. Disko configuration (if any):"
if [ -f /etc/disko.json ]; then
    echo "Disko config found:"
    cat /etc/disko.json | jq . 2>/dev/null || cat /etc/disko.json
else
    echo "No disko configuration found"
fi
echo

echo "7. Available space:"
sudo vgs 2>/dev/null && echo "LVM volume groups found" || echo "No LVM detected"
sudo btrfs filesystem usage / 2>/dev/null && echo "Btrfs detected" || echo "No Btrfs on root"
echo

echo "8. Current NixOS generation:"
nixos-version
nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -3

echo
echo "=== End of disk inspection ==="
