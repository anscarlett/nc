# Template Configuration Guide

This repository includes example configurations that you can copy and customize. All naming is derived from the filesystem structure - no hardcoded values.

## 📁 Understanding the Structure

```
minimal-nixos/
├── hosts/
│   └── example/           # hostname = "example"
│       ├── host.nix       # System configuration  
│       └── secrets.yaml   # System secrets (WiFi, VPN, etc.)
└── users/
    └── example/           # username = "example"  
        ├── user.nix       # User configuration (Home Manager)
        └── secrets.yaml   # User secrets (SSH keys, tokens, etc.)
```

**Names are automatically derived from folder structure:**
- `hosts/mylaptop/` → hostname becomes `mylaptop`
- `users/john/` → username becomes `john`

## 🔧 Creating Your Configuration

### Method 1: Copy Example (Recommended)

```bash
# Copy example host configuration
cp -r hosts/example hosts/mylaptop

# Copy example user configuration  
cp -r users/example users/john

# Edit the copied files:
# - hosts/mylaptop/host.nix
# - users/john/user.nix
```

### Method 2: Create From Scratch

```bash
# Create directories
mkdir -p hosts/mylaptop users/john

# Copy just the nix files (without secrets)
cp hosts/example/host.nix hosts/mylaptop/
cp users/example/user.nix users/john/
```

## ✏️ Customization Points

### In `hosts/mylaptop/host.nix`:

1. **Disk device** (CRITICAL):
   ```nix
   (import ../../modules/disko.nix {
     disk = "/dev/nvme0n1";  # ← CHANGE THIS
     luksName = "cryptlaptop";
     enableYubikey = true;
   })
   ```

2. **User password**:
   ```bash
   # Generate hash
   nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'
   ```
   ```nix
   users.users.john.hashedPassword = "GENERATED_HASH_HERE";
   ```

3. **Hardware modules** (if needed):
   ```nix
   imports = [
     # Add hardware-specific modules
     inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
   ];
   ```

### In `users/john/user.nix`:

1. **Personal details**:
   ```nix
   programs.git = {
     userName = "John Smith";      # ← CHANGE THIS
     userEmail = "john@email.com"; # ← CHANGE THIS
   };
   ```

2. **Home directory structure**:
   ```nix
   home.persistence."/persist/home/john" = {  # ← Username matches folder
     directories = [
       "Documents"
       "Projects"  # ← Customize for your needs
       ".config"
     ];
   };
   ```

## 🔐 Secrets Setup (Optional)

### Generate Age Key
```bash
# Create age identity
mkdir -p ~/.config/age
nix-shell -p age --run 'age-keygen -o ~/.config/age/keys.txt'

# Show your public key
grep "public key:" ~/.config/age/keys.txt
```

### Configure SOPS
Create `.sops.yaml` in repository root:
```yaml
keys:
  - &mykey age1abc123your-age-public-key-here

creation_rules:
  - path_regex: \.yaml$
    key_groups:
      - age:
          - *mykey
```

### Create and Encrypt Secrets
```bash
# Edit host secrets
nix-shell -p sops --run 'sops hosts/mylaptop/secrets.yaml'

# Edit user secrets  
nix-shell -p sops --run 'sops users/john/secrets.yaml'
```

## 🏗️ Build Your System

```bash
# Check configuration is valid
nix flake check

# Build (without switching)
nixos-rebuild build --flake .#mylaptop

# Deploy to system
sudo nixos-rebuild switch --flake .#mylaptop
```

## 🔍 Finding Your Disk Device

### List All Disks
```bash
# Simple view
lsblk

# Detailed view with filesystems
lsblk -f

# All disk information
sudo fdisk -l
```

### Recommended Disk Identifiers
Use stable identifiers instead of `/dev/sdX`:

```bash
# By ID (most stable)
ls -la /dev/disk/by-id/

# Example:
disk = "/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S123456789";
```

## 🎯 Multiple Configurations

You can have multiple hosts and users:

```
hosts/
├── laptop/        # Personal laptop
├── desktop/       # Gaming desktop  
├── server/        # Home server
└── work-laptop/   # Work machine

users/
├── personal/      # Personal identity
├── work/          # Work identity
└── admin/         # Server admin
```

Each gets built automatically:
```bash
sudo nixos-rebuild switch --flake .#laptop
sudo nixos-rebuild switch --flake .#work-laptop
home-manager switch --flake .#personal
```

## 🔄 Architecture Support

The flake automatically detects architecture from hostname:
- `*rock5b*`, `*rpi*`, `*arm*` → `aarch64-linux`
- Everything else → `x86_64-linux`

Override in host.nix if needed:
```nix
# Force specific architecture
nixpkgs.hostPlatform = "aarch64-linux";
```

## 📝 Common Patterns

### Laptop Configuration
```nix
# hosts/laptop/host.nix
{
  # Power management
  services.tlp.enable = true;
  
  # Laptop hardware
  services.xserver.libinput.enable = true;
  hardware.bluetooth.enable = true;
}
```

### Server Configuration  
```nix
# hosts/server/host.nix
{
  # No desktop
  imports = [
    ../../modules/core.nix
    # Skip desktop.nix
  ];
  
  # Server services
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
}
```

### Work User
```nix
# users/work/user.nix
{
  programs.git.userEmail = "work@company.com";
  
  home.packages = with pkgs; [
    teams-for-linux
    slack
    zoom-us
  ];
}
```

This approach maintains purity while providing maximum flexibility through pure filesystem-based configuration discovery.