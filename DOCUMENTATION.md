# NixOS Configuration Documentation

This repository contains a modular NixOS flake-based configuration for building NixOS hosts and managing users with Home Manager.

## 📚 Documentation

### 🔑 YubiKey Security Setup
- **[YubiKey Overview](docs/yubikey-overview.md)** - Main guide with navigation paths
- **[Quick Setup](docs/yubikey-quick-setup.md)** - Essential YubiKey setup in 30 minutes
- **[Pre-deployment Checklist](docs/yubikey-checklist.md)** - What to prepare vs. on-site setup
- **[Complete Reference](docs/yubikey-general.md)** - Comprehensive YubiKey guide (all features)
- **[LUKS Installation Guide](docs/yubikey-luks.md)** - YubiKey LUKS setup for NixOS installer

### 🛠️ System Configuration
- **[Customization Guide](docs/customisation.md)** - How to customize this configuration
- **[VM Testing](docs/vm-testing.md)** - Testing configurations in virtual machines

## 🚀 Quick Start

1. **For new users**: Start with [YubiKey Overview](docs/yubikey-overview.md)
2. **For quick setup**: Use [Quick Setup Guide](docs/yubikey-quick-setup.md)
2. **For system customization**: See [Customization Guide](docs/customisation.md)

## 📁 Repository Structure

```
├── docs/              # All documentation
├── hosts/             # Host-specific configurations
├── homes/             # Home Manager user configurations
├── modules/           # Reusable NixOS modules
├── lib/               # Library functions
├── outputs/           # Flake outputs
└── scripts/           # Utility scripts
```

## 🔧 Configuration Features

- **Modular design** - Easy to customize and extend
- **Auto-discovery** - Automatically finds hosts and users
- **YubiKey integration** - Hardware security for LUKS, SSH, 2FA
- **Disko support** - Declarative disk partitioning
- **Home Manager** - User environment management
- **Multiple desktops** - GNOME, Hyprland, KDE, DWM support

## 🛡️ Security Features

- **YubiKey LUKS unlock** - Disk encryption without passwords
- **Hardware SSH keys** - SSH authentication via YubiKey
- **2FA integration** - YubiKey as authenticator app
- **GPG on hardware** - Signing and encryption keys on YubiKey
- **PAM integration** - System login via YubiKey

## 📖 Getting Started

1. Clone this repository
2. Review [Customization Guide](docs/customisation.md) 
3. Configure your hosts in `hosts/`
4. Configure your users in `homes/`
5. Follow [YubiKey setup](docs/yubikey-overview.md) for security features
6. Build and deploy with `nixos-rebuild`

For detailed setup instructions, see the documentation in the `docs/` folder.
