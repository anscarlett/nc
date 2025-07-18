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
read -p "Enter your username (e.g., adrianscarlett-work or just adrianscarlett): " USERNAME
read -p "Enter your full name: " FULLNAME
read -p "Enter your email: " EMAIL
read -p "Enter your hostname (e.g., work-laptop or just laptop): " HOSTNAME

echo "📝 Creating folder structure and updating configuration files..."

# Parse username to create homes folder structure
# Username format: "user-context" -> homes/context/user/ OR "user" -> homes/user/
if [[ "$USERNAME" == *-* ]]; then
    USER_PART="${USERNAME%-*}"     # Everything before last hyphen
    CONTEXT_PART="${USERNAME##*-}" # Everything after last hyphen
    USER_DIR="homes/$CONTEXT_PART/$USER_PART"
else
    # Single name username - no context folder needed
    USER_DIR="homes/$USERNAME"
fi

# Parse hostname to create hosts folder structure  
# Hostname format: "context-host" -> hosts/context/host/ OR "host" -> hosts/host/
if [[ "$HOSTNAME" == *-* ]]; then
    HOST_CONTEXT="${HOSTNAME%-*}"   # Everything before last hyphen
    HOST_PART="${HOSTNAME##*-}"     # Everything after last hyphen
    HOST_DIR="hosts/$HOST_CONTEXT/$HOST_PART"
else
    # Single name hostname - no context folder needed
    HOST_DIR="hosts/$HOSTNAME"
fi

# Create the user directory structure
echo "Creating user directory: $USER_DIR"
mkdir -p "$USER_DIR"

# Copy template files if they exist and source is different from destination
if [ -d "homes/username" ]; then
    cp -r "homes/username/"* "$USER_DIR/"
    rm -rf "homes/username"
    echo "✅ Created user directory structure: $USER_DIR"
fi

# Create the host directory structure
echo "Creating host directory: $HOST_DIR"
mkdir -p "$HOST_DIR"

# Copy template files if they exist and source is different from destination
if [ -d "hosts/hostname" ]; then
    cp -r "hosts/hostname/"* "$HOST_DIR/"
    rm -rf "hosts/hostname"
    echo "✅ Created host directory structure: $HOST_DIR"
fi

# Update home.nix
if [ -f "$USER_DIR/home.nix" ]; then
    sed -i "s/Your Name/$FULLNAME/g" "$USER_DIR/home.nix"
    sed -i "s/your.email@company.com/$EMAIL/g" "$USER_DIR/home.nix"
    echo "✅ Updated home.nix with your details (username auto-derived: $USERNAME)"
fi

# Host configuration uses auto-detection - no manual updates needed
echo "✅ Host configuration will auto-detect hostname: $HOSTNAME"

# Update flake.nix if needed
echo "✅ Flake configuration ready"

# Check for public repo access
echo "🔍 Checking access to public repository..."
if command -v nix &> /dev/null; then
    if nix flake show --extra-experimental-features nix-command --extra-experimental-features flakes github:anscarlett/nc &> /dev/null; then
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
echo "   # Copy the hash to the userPasswords section in $HOST_DIR/host.nix"
echo ""
echo "2. Set up secrets (optional):"
echo "   nix-shell -p age -p agenix --run 'age-keygen -o ~/.config/age/keys.txt'"
echo "   # Update both secrets.nix files with your public key:"
echo "   #   - $HOST_DIR/secrets.nix"
echo "   #   - $USER_DIR/secrets.nix"
echo ""
echo "3. Build your configuration:"
echo "   sudo nixos-rebuild switch --flake .#$HOSTNAME"
echo ""
echo "4. Build home manager:"
echo "   home-manager switch --flake .#$USERNAME"
echo ""
echo "📚 See README.md for detailed instructions"
