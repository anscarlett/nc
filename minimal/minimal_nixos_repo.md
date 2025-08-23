# Minimal NixOS Configuration

A minimal, secure NixOS setup with YubiKey integration, focused on getting systems running quickly.

## 🚀 Quick Start

1. **Clone and setup**: `git clone <this-repo> && cd minimal-nixos && ./setup.sh`
2. **Configure YubiKey**: Follow [YubiKey Setup](#yubikey-setup) below
3. **Deploy**: `sudo nixos-rebuild switch --flake .#<hostname>`

## 📁 Repository Structure

```
minimal-nixos/
├── flake.nix                 # Main flake with all inputs
├── setup.sh                  # Interactive setup script
├── lib/                      # Auto-discovery functions
│   ├── mk-configs.nix        # Host/user discovery
│   └── get-name.nix          # Path to name conversion
├── modules/
│   ├── core.nix              # Essential system config
│   ├── desktop.nix           # Hyprland + essentials
│   ├── disko.nix             # Btrfs + LUKS + YubiKey
│   └── secrets.nix           # Secrets management
├── hosts/
│   └── example/
│       ├── host.nix          # Example host → example
│       └── secrets.nix       # Host secrets
├── users/
│   └── example/
│       ├── user.nix          # Example user → example
│       └── secrets.nix       # User secrets
└── docs/
    ├── YUBIKEY.md            # Complete YubiKey guide
    └── PRIVATE.md            # Private repo setup
```

## 🔑 YubiKey Setup

### Step 1: Prepare YubiKey (5 minutes)

```bash
# Install tools
nix-shell -p yubikey-manager

# Check YubiKey detection
ykman info

# Enable all interfaces
ykman config usb --enable-all

# Configure slot 2 for LUKS (overwrites existing!)
ykman otp chalresp --generate 2

# Test it works
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

### Step 2: Basic 2FA Setup (10 minutes)

```bash
# Add essential accounts
ykman oath accounts add "GitHub:yourusername" <secret-from-qr>
ykman oath accounts add "Google:youremail" <secret-from-qr>

# Test code generation
ykman oath accounts code

# CRITICAL: Backup secrets
ykman oath accounts uri "GitHub:yourusername" > github-backup.txt
# Store this file on encrypted USB drive!
```

### Step 3: Configure System (10 minutes)

```bash
# Run setup script
./setup.sh

# Edit host config - set your disk device
# Edit user config - set your details
# Generate password hash: mkpasswd -m sha-512

# Deploy
sudo nixos-rebuild switch --flake .#<hostname>
```

## 🛡️ Security Features Included

- **Btrfs**: Modern filesystem with snapshots
- **LUKS**: Full disk encryption
- **YubiKey unlock**: No password needed for boot
- **Impermanence**: Fresh system on every boot
- **Stylix**: Consistent theming
- **Sops-nix**: Secrets management
- **Hyprland**: Modern Wayland compositor
- **PipeWire**: Modern audio system

## 📋 System Features

- **Auto-discovery**: Hosts and users from folder structure
- **Minimal**: Only essential packages included
- **Extensible**: Easy to add more features
- **Private-ready**: Template for private configurations

## 🔄 Moving to Private Repository

When ready for work/private configs:

```bash
# Copy template
cp -r private-template/ ../my-private-nixos/
cd ../my-private-nixos/

# Customize
./setup.sh

# This repo becomes your private extension
```

## 📚 Documentation

- **[YubiKey Guide](docs/YUBIKEY.md)**: Complete YubiKey setup
- **[Private Setup](docs/PRIVATE.md)**: Private repository configuration

## 🎯 Philosophy

- **Minimal by default**: Only what you need to get running
- **Security first**: YubiKey integration from day one
- **Auto-discovery**: No manual configuration registration
- **Extension ready**: Easy to add features without modification