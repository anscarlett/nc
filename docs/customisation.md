# NixOS Configuration Customization Guide

This guide explains how to customize your NixOS configuration across different levels of the system.

## 📦 Adding Applications

### System-wide Applications (Always Installed)

Applications that should be available on **all systems** go in different modules depending on their purpose:

#### Core Applications (`modules/core/default.nix`)
Essential system tools and utilities that every system needs:
```nix
environment.systemPackages = with pkgs; [
  vim          # Always have a basic editor
  wget         # Download utility
  git          # Version control
  curl         # HTTP client
  htop         # Process monitor
  tree         # Directory tree viewer
];
```

#### Desktop Applications (`modules/desktop/default.nix`)
Applications for **all desktop environments** (GNOME, KDE, Hyprland, etc.):
```nix
environment.systemPackages = with pkgs; [
  firefox      # Web browser
  vscode       # Code editor
  alacritty    # Terminal emulator
  pavucontrol  # Audio control
  flameshot    # Screenshots
];
```

#### Desktop Environment Specific
For applications specific to one desktop environment:
- **Hyprland**: `modules/desktop/hyprland/default.nix`
- **GNOME**: `modules/desktop/gnome/default.nix`
- **KDE**: `modules/desktop/kde/default.nix`

### Per-User Applications (Home Manager)

User-specific applications go in home configurations (`homes/*/home.nix`):
```nix
home.packages = with pkgs; [
  discord      # User's personal apps
  spotify
  gimp
];
```

### Per-Host Applications

Host-specific applications go in the individual host file (`hosts/*/host.nix`):
```nix
environment.systemPackages = with pkgs; [
  steam        # Gaming laptop only
  obs-studio   # Streaming setup
];
```

## 🏠 User Management

### System User vs Home Manager User

**Important**: These are two different but connected concepts:

1. **System User** - The actual user account on NixOS (login credentials, groups, shell)
2. **Home Manager User** - The user's personal configuration (dotfiles, user apps, settings)

### Current Approach: Manual User-to-Home Mapping

For now, you need to manually specify which users and home configurations to use in each host:

```nix
# In hosts/*/host.nix
{
  # Create system users
  users.users = {
    adrian = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
      shell = pkgs.zsh;
      hashedPassword = "your-hashed-password";
    };
    
    adrianscarlett = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
      shell = pkgs.zsh;
      hashedPassword = "work-hashed-password";
    };
  };

  # Link to specific home manager configs
  home-manager.users = {
    adrian = import ../../../homes/home/adrian/home.nix inputs;
    adrianscarlett = import ../../../homes/ct/adrianscarlett/home.nix inputs;
  };
}
```

### Future Enhancement: Automatic User Creation ✨

**Coming Soon**: Automatic user creation from home manager configurations!

The goal is to have users automatically created based on your `homes/` directory structure:
- `homes/home/adrian/home.nix` → Automatically creates system user `adrian`
- `homes/ct/adrianscarlett/home.nix` → Automatically creates system user `adrianscarlett`

This feature is being developed and will be available in a future update.

### Per-Host User Selection

Different hosts can use different combinations of users:

**Work Laptop**:
```nix
home-manager.users.adrianscarlett = import ../../../homes/ct/adrianscarlett/home.nix inputs;
```

**Personal Desktop**:
```nix
home-manager.users.adrian = import ../../../homes/home/adrian/home.nix inputs;
```

**Gaming Server**:
```nix
home-manager.users.adrian = import ../../../homes/home/servers/gaming/adrian/home.nix inputs;
```

### Home Manager Configuration (`homes/*/home.nix`)
User's **personal configuration** (runs after login):
```nix
# This configures what happens AFTER the user logs in
programs.git = {
  enable = true;
  userName = "Adrian";
  userEmail = "your@email.com";
};

programs.zsh = {
  # Personal shell configuration (dotfiles)
};

home.packages = with pkgs; [
  # User-specific applications
  discord
  spotify
];
```

## 🖥️ Desktop Environments

### Switching Desktop Environments

In your host configuration (`hosts/*/host.nix`), import the desired desktop module:

```nix
imports = [
  ../../../common.nix
  ../../../modules/core
  ../../../modules/desktop/hyprland    # For Hyprland
  # ../../../modules/desktop/gnome     # For GNOME
  # ../../../modules/desktop/kde       # For KDE
];
```

### Desktop-Specific Packages

Add packages specific to a desktop environment in its module:

**Hyprland** (`modules/desktop/hyprland/default.nix`):
```nix
environment.systemPackages = with pkgs; [
  waybar       # Wayland status bar
  wofi         # Application launcher
  swww         # Wallpaper daemon
];
```

## 💾 Disk Layouts

### Simple Layout (Current VM)
Basic filesystem setup in host configuration:
```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/nixos";
  fsType = "ext4";
};
```

### Advanced Layouts (Disko)
Use disko presets for complex setups:

**Encrypted Btrfs** (`modules/disko-presets/btrfs-flex.nix`):
```nix
# In your host config
imports = [
  (import ../../modules/disko-presets/btrfs-flex.nix {
    disk = "/dev/nvme0n1";
    luksName = "cryptroot";
    enableImpermanence = true;
  })
];
```

**LVM Setup** (`modules/disko-presets/lvm-basic.nix`):
```nix
# In your host config
imports = [
  (import ../../modules/disko-presets/lvm-basic.nix {
    disk = "/dev/sda";
    vgName = "system";
    swapSize = "8G";
    homeSize = "100G";
  })
];
```

## 🌐 Services

### System Services (`modules/core/default.nix`)
Enable services that all systems need:
```nix
services.openssh.enable = true;
services.fail2ban.enable = true;
```

### Desktop Services (`modules/desktop/default.nix`)
Services for desktop systems:
```nix
services.printing.enable = true;
services.bluetooth.enable = true;
```

### Host-Specific Services
Enable services only on certain hosts:
```nix
# In hosts/home/server/host.nix
services.jellyfin.enable = true;
services.nextcloud.enable = true;
```

## 🔧 Hardware Configuration

### Per-Host Hardware Settings
Hardware-specific configuration goes in individual host files:
```nix
# Graphics
hardware.opengl.enable = true;
hardware.nvidia.enable = true;

# Audio
hardware.pulseaudio.enable = false; # Using PipeWire instead

# Power management for laptops
services.tlp.enable = true;
```

## 📁 File Structure Summary

```
├── modules/
│   ├── core/           # Essential system config & packages
│   ├── desktop/        # Desktop environment configs
│   │   ├── default.nix # Common desktop packages
│   │   ├── hyprland/   # Hyprland-specific
│   │   ├── gnome/      # GNOME-specific
│   │   └── kde/        # KDE-specific
│   └── disko-presets/ # Disk layout templates
├── hosts/              # Per-machine configuration
│   ├── vm/test/        # VM for testing
│   ├── home/legion/    # Gaming laptop
│   └── home/rock5b/    # ARM SBC
└── homes/              # User configurations (Home Manager)
    ├── home/adrian/    # Personal desktop config
    └── ct/adrianscarlett/ # Work config
```

## 🚀 Quick Examples

### Add a Package System-wide
```bash
# Edit modules/core/default.nix
environment.systemPackages = with pkgs; [
  # existing packages...
  neofetch  # Add this line
];
```

### Add User-Specific Package
```bash
# Edit homes/home/adrian/home.nix
home.packages = with pkgs; [
  # existing packages...
  discord  # Add this line
];
```

### Create New Host
```bash
# 1. Create directory
mkdir -p hosts/new/hostname

# 2. Create host.nix based on existing examples
# 3. Add to flake outputs (automatic with current setup)
```

### Switch Desktop Environment
```bash
# In hosts/your-host/host.nix, change import:
# FROM: ../../../modules/desktop/gnome
# TO:   ../../../modules/desktop/hyprland
```