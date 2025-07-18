# NixOS Configuration

A minimal, modular NixOS system configuration using flakes with comprehensive YubiKey security integration.

📚 **For detailed documentation, see [DOCUMENTATION.md](DOCUMENTATION.md)**

## Quick Start

1. **System setup**: Follow this README for basic NixOS configuration
2. **YubiKey security**: See [docs/yubikey-overview.md](docs/yubikey-overview.md) for hardware security features
3. **Customization**: See [docs/CUSTOMISATION.md](docs/CUSTOMISATION.md) for configuration details

## Structure

The configuration is organized into separate directories for better maintainability:

```
.
├── hosts/              # NixOS system configurations
│   ├── ct/
│   │   └── laptop/
│   │       └── host.nix  # Hostname: ct-laptop
│   └── home/
│       └── legion/
│           └── host.nix  # Hostname: home-legion
│
├── homes/              # Home-manager user configurations
│   ├── ct/
│   │   └── adrian.scarlett/
│   │       └── home.nix  # Username: adrian.scarlett-ct
│   └── home/
│       ├── adrian/
│       │   └── home.nix  # Username: adrian-home
│       └── servers/
│           └── gaming/
│               └── adrian/
│                   └── home.nix  # Username: adrian-gaming-servers-home
│
├── inputs/             # Flake inputs (automatically imported)
│   ├── nixpkgs.nix     # nixpkgs source
│   ├── home-manager.nix # home-manager
│   ├── agenix.nix      # secrets management
│   └── nixos-hardware.nix  # hardware configurations
│
├── lib/                # Helper functions
│   ├── constants.nix    # Shared constants (e.g., NixOS version)
│   ├── import-all.nix   # Auto-import inputs
│   ├── import-outputs.nix # Auto-import outputs
│   ├── mk-hosts.nix     # Generate host configurations
│   ├── mk-homes.nix     # Generate home configurations
│   └── get-username.nix # Generate usernames from paths
│
├── outputs/            # Flake outputs
│   ├── nixos-configurations.nix  # System configurations
│   └── home-configurations.nix   # User configurations
│
└── flake.nix          # Minimal flake that imports all components
```

## Structure

### Hosts
System configurations are organized in the `hosts/` directory. The hostname is generated from the path:
```
hosts/ct/laptop/host.nix     → ct-laptop
hosts/home/legion/host.nix    → home-legion
```

### Homes
User configurations are organized in the `homes/` directory. The username is generated from the path in reverse order:
```
homes/ct/adrian.scarlett/home.nix          → adrian.scarlett-ct
homes/home/adrian/home.nix                 → adrian-home
homes/home/servers/gaming/adrian/home.nix  → adrian-gaming-servers-home
```

### Automatic Imports
All `.nix` files in the `inputs/` directory are automatically imported. You don't need to manually add new inputs to `flake.nix`.

## Usage

### Building System Configurations
```bash
# Build and switch to a system configuration (combines NixOS + Home Manager)
sudo nixos-rebuild switch --flake .#laptop-ct     # Build CT laptop
sudo nixos-rebuild switch --flake .#legion-home   # Build home Legion
sudo nixos-rebuild switch --flake .#rock5b-home   # Build Rock5B server
sudo nixos-rebuild switch --flake .#test-vm       # Build test VM
```

### Building Home Configurations (standalone)
```bash
# If you want to use Home Manager standalone (not integrated with NixOS)
home-manager switch --flake .#adrian.scarlett-ct  # Build CT work profile
home-manager switch --flake .#adrian-home         # Build home profile
```

### Setting up a new system

1. **Generate a password hash:**
   ```bash
   ./scripts/generate-password.sh yourpassword
   ```

2. **Update the host configuration with the password hash:**
   Replace the placeholder `$6$rounds=4096$...` in your host config with the generated hash.

3. **Build the system:**
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   ```

## Design Philosophy

- Each file has a single responsibility
- Inputs and outputs are separated into their own files
- The main `flake.nix` is kept minimal and only combines the modular pieces
- Easy to maintain and extend without cluttering the main configuration

## Usage

To rebuild your system with this configuration:

```bash
sudo nixos-rebuild switch --flake .#hostname
```

Replace `hostname` with your system's hostname as defined in the configuration.

## Setup

1. Generate an SSH key if you haven't already:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. Add your SSH key to your Git provider (e.g., GitHub, GitLab)

3. Initialize the git repository and push:
   ```bash
   git init
   git add .
   git commit -m "Initial NixOS configuration"
   git remote add origin git@github.com:username/nixos-config.git
   git push -u origin main
   ```

4. Build the configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   ```
