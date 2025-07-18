#!/usr/bin/env bash
# Setup script for private NixOS configuration

set -e

echo "🚀 Setting up private NixOS configuration..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository. Please run 'git init' first."
    exit 1
fi

# Get user input
read -p "Enter your username: " USERNAME
read -p "Enter your full name: " FULLNAME
read -p "Enter your email: " EMAIL
read -p "Enter your hostname (default: work-laptop): " HOSTNAME
HOSTNAME=${HOSTNAME:-work-laptop}

echo "📝 Updating configuration files..."

# Update folder structure
if [ -d "homes/work/your-username" ]; then
    mv "homes/work/your-username" "homes/work/$USERNAME"
    echo "✅ Renamed user directory to homes/work/$USERNAME"
fi

# Update home.nix
if [ -f "homes/work/$USERNAME/home.nix" ]; then
    sed -i "s/Your Name/$FULLNAME/g" "homes/work/$USERNAME/home.nix"
    sed -i "s/your.email@company.com/$EMAIL/g" "homes/work/$USERNAME/home.nix"
    echo "✅ Updated home.nix with your details (username auto-derived from folder)"
fi

# Host configuration uses auto-detection - no manual updates needed
echo "✅ Host configuration will auto-detect hostname from folder structure"

# Update flake.nix if needed
echo "✅ Flake configuration ready"

# Check for public repo access
echo "🔍 Checking access to public repository..."
if command -v nix &> /dev/null; then
    if nix flake show github:anscarlett/nc &> /dev/null; then
        echo "✅ Can access public repository"
    else
        echo "⚠️  Cannot access public repository. Check your internet connection."
    fi
else
    echo "⚠️  Nix not found. Make sure you're on a NixOS system."
fi

echo ""
echo "🎉 Setup complete! Next steps:"
echo ""
echo "1. Generate a password hash:"
echo "   nix run nixpkgs#mkpasswd -- -m sha-512"
echo "   # Copy the hash to the userPasswords section in hosts/ct/laptop/host.nix"
echo ""
echo "2. Set up secrets (optional):"
echo "   nix-shell -p age -p agenix --run 'age-keygen -o ~/.config/age/keys.txt'"
echo "   # Update both secrets.nix files with your public key:"
echo "   #   - hosts/work/laptop/secrets.nix"
echo "   #   - homes/work/$USERNAME/secrets.nix"
echo ""
echo "3. Build your configuration:"
echo "   sudo nixos-rebuild switch --flake .#$HOSTNAME"
echo ""
echo "4. Build home manager:"
echo "   home-manager switch --flake .#$USERNAME-work"
echo ""
echo "📚 See README.md for detailed instructions"
