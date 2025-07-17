# VM Testing Guide

## Quick Start

To test your NixOS configuration in a virtual machine:

```bash
# Build and test the VM configuration
./scripts/test-config.sh

# Start the VM (4GB RAM, 2 cores by default)
./scripts/test-vm.sh

# Start VM with custom resources
./scripts/test-vm.sh vm-test 8192 4  # 8GB RAM, 4 cores
```

## What to Test

Once the VM starts, you can test:

### 1. Basic System Functionality
- **Login**: Use username `adrian` (password from your configuration)
- **Root access**: User should have sudo access via wheel group
- **System info**: Run `nixos-version` to verify NixOS version

### 2. Desktop Environment (Hyprland)
- **First boot**: Hyprland will start automatically
- **Initial setup**: Copy the example config:
  ```bash
  mkdir -p ~/.config/hypr
  cp /home/adrianscarlett/projects/nixos/nc/examples/hyprland.conf ~/.config/hypr/
  ```
- **Key bindings**:
  - `Super + Q`: Open terminal (Alacritty)
  - `Super + R`: Open application launcher (Wofi)
  - `Super + C`: Close window
  - `Super + M`: Exit Hyprland
  - `Super + 1-9`: Switch workspaces
  - `Super + Shift + 1-9`: Move window to workspace
- **Status bar**: Waybar should appear at the top
- **Notifications**: Mako handles notifications

### 3. SSH Access
From your host machine:
```bash
# SSH into the VM (port 2222 is forwarded to VM's port 22)
ssh -p 2222 adrian@localhost
```

### 4. Home Manager Integration
```bash
# Check if Home Manager is working
home-manager --version

# List Home Manager generations
home-manager generations
```

### 5. Package Management
```bash
# Test Nix commands
nix --version
nix search nixpkgs firefox

# Test unfree packages (if configured)
nix search nixpkgs vscode
```

### 6. System Services
```bash
# Check critical services
systemctl status openssh
systemctl status NetworkManager
systemctl status pipewire  # For audio
```

## Networking

The VM is configured with:
- NAT networking (can access internet)
- SSH port forwarding: Host:2222 → VM:22
- Display forwarding for GUI applications

## Troubleshooting

### VM Won't Start
1. Check if virtualization is enabled in BIOS
2. Ensure QEMU/KVM is installed: `nix-shell -p qemu`
3. Check available disk space

### SSH Connection Issues
```bash
# Reset SSH known hosts if needed
ssh-keygen -R "[localhost]:2222"

# Connect with verbose output
ssh -v -p 2222 adrian@localhost
```

### Hyprland Issues
```bash
# If Hyprland doesn't start properly
journalctl -u display-manager

# Check if Hyprland is running
ps aux | grep hyprland

# Test Hyprland config
hyprctl version

# Restart Hyprland session
Super + M (exit) then log back in
```
- Increase VM memory: `./scripts/test-vm.sh vm-test 8192`
- Enable KVM acceleration (automatic if available)
- Close other applications to free resources

### Configuration Errors
```bash
# Check build errors
nix flake check

# Test specific configuration
nix build .#nixosConfigurations.vm-test.config.system.build.toplevel
```

## Testing Other Configurations

To test different host configurations:

```bash
# Test laptop configuration
nix build .#nixosConfigurations.ct-laptop.config.system.build.vm
result/bin/run-*-vm

# Test server configuration  
nix build .#nixosConfigurations.home-legion.config.system.build.vm
result/bin/run-*-vm
```

## Cleanup

```bash
# Remove VM build artifacts
rm -rf result

# Clean Nix store (optional)
nix-collect-garbage
```
