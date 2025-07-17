#!/usr/bin/env bash
# Generate a password hash for NixOS user configuration

if [ -z "$1" ]; then
    echo "Usage: $0 <password>"
    echo "Example: $0 mypassword"
    exit 1
fi

echo "Generating password hash for: $1"
echo "Copy this hash to your host configuration:"
echo ""
mkpasswd -m sha-512 "$1"
