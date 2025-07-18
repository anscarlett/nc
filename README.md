# NixOS Configuration

A minimal, modular NixOS system configuration using flakes with comprehensive YubiKey security integration.

## ⚡ Quick Start

1. **System setup**: Follow this README for basic NixOS configuration
2. **YubiKey security**: See [docs/yubikey-overview.md](docs/yubikey-overview.md) for hardware security features
3. **Customization**: See [docs/customisation.md](docs/customisation.md) for configuration details

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
- **[Private Config Setup](docs/private-config.md)** - Using this config with private work repositories
- **[Private Template](private-template/)** - Ready-to-use template for private repositories

## 📁 Repository Structure

```
├── docs/              # 📚 All documentation
├── hosts/             # 🖥️ NixOS system configurations
│   ├── ct/laptop/     #     → ct-laptop
│   └── home/legion/   #     → home-legion
├── homes/             # 🏠 Home Manager user configurations  
│   ├── ct/adrianscarlett/    #     → adrianscarlett-ct
│   └── home/adrian/   #     → adrian-home
├── modules/           # 🧩 Reusable NixOS modules
│   ├── core/          #     Essential system components
│   ├── desktop/       #     Desktop environments (GNOME, Hyprland, etc.)
│   └── disko-presets/ #     Disk partitioning templates
├── lib/               # 🔧 Helper functions
├── outputs/           # 📤 Flake outputs (auto-generated)
├── scripts/           # 🛠️ Utility scripts
└── flake.nix         # ❄️ Main flake configuration
```

## 🔧 Key Features

- **🧩 Modular design** - Easy to customize and extend
- **🔍 Auto-discovery** - Automatically finds hosts and users from folder structure
- **🔐 YubiKey integration** - Hardware security for LUKS, SSH, 2FA, GPG
- **💾 Disko support** - Declarative disk partitioning with encryption
- **🏠 Home Manager** - User environment management integrated with NixOS
- **🖥️ Multiple desktops** - GNOME, Hyprland, KDE, DWM support
- **📱 VM testing** - Easy configuration testing in virtual machines

## 🛡️ Security Features

- **YubiKey LUKS unlock** - Disk encryption without passwords
- **Hardware SSH keys** - SSH authentication via YubiKey
- **2FA integration** - YubiKey as authenticator app
- **GPG on hardware** - Signing and encryption keys on YubiKey
- **PAM integration** - System login via YubiKey

## 🏗️ How It Works

### 🖥️ Hosts (System Configurations)
```
hosts/ct/laptop/host.nix     → ct-laptop
hosts/home/legion/host.nix   → home-legion
```

### 🏠 Homes (User Configurations) 
```
homes/ct/adrianscarlett/home.nix    → adrianscarlett-ct
homes/home/adrian/home.nix          → adrian-home
```

### 🔄 Auto-Discovery
The configuration automatically discovers and builds all hosts and users from the folder structure - no manual registration needed!

## 🚀 Usage

### Building Complete Systems (NixOS + Home Manager)
```bash
# Build and switch to a system configuration (combines NixOS + Home Manager)
sudo nixos-rebuild switch --flake .#ct-laptop     # Build CT laptop
sudo nixos-rebuild switch --flake .#home-legion   # Build home Legion
sudo nixos-rebuild switch --flake .#home-rock5b   # Build Rock5B server
sudo nixos-rebuild switch --flake .#vm-test       # Build test VM
```

### Building Home Manager Only (Standalone)
```bash
# If you want to use Home Manager standalone (not integrated with NixOS)
home-manager switch --flake .#adrianscarlett-ct   # Build CT work profile
home-manager switch --flake .#adrian-home         # Build home profile
```

## 🛠️ Setup Guide

### 1. 🔐 Generate Password Hash
```bash
./scripts/generate-password.sh yourpassword
```

### 2. ⚙️ Configure Host
Update your host configuration with the generated password hash (replace placeholder `$6$rounds=4096$...`).

### 3. 🏗️ Build System
```bash
sudo nixos-rebuild switch --flake .#hostname
```

## 🎯 Design Philosophy

- **Single responsibility** - Each file has one clear purpose
- **Modular architecture** - Easy to maintain and extend
- **Minimal main config** - `flake.nix` just combines modular pieces
- **Auto-discovery** - No manual registration of hosts/users needed

## 📖 Getting Started

### For New Users
1. **🔍 Read the docs**: Start with [YubiKey Overview](docs/yubikey-overview.md) for security setup
2. **⚡ Quick setup**: Use [Quick Setup Guide](docs/yubikey-quick-setup.md) for 30-minute YubiKey config
3. **🎨 Customize**: See [Customization Guide](docs/customisation.md) for configuration options
4. **🧪 Test safely**: Use [VM Testing](docs/vm-testing.md) before deploying to real hardware

### Complete Setup Process
1. Clone this repository
2. Review [Customization Guide](docs/customisation.md) for your needs
3. Configure your hosts in `hosts/` directory
4. Configure your users in `homes/` directory  
5. Follow [YubiKey setup](docs/yubikey-overview.md) for hardware security
6. Build and deploy with `nixos-rebuild switch --flake .#hostname`

For detailed setup instructions, see the documentation in the `docs/` folder.
