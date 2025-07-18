# NixOS Configuration Framework

A modular, secure, and automated NixOS configuration system with Home Manager integration, featuring automatic discovery, secrets management, and comprehensive testing.

## ✨ Features

- **🔧 Modular Architecture**: Organized modules for core, desktop, server, and installer configurations
- **🏠 Home Manager Integration**: Both NixOS module and standalone home-manager support
- **🔍 Auto-Discovery**: Automatic detection of hosts and users from folder structure
- **� Secrets Management**: Integrated agenix support with co-located secrets
- **🖥️ Multiple Desktop Environments**: Hyprland, GNOME, KDE, DWM support
- **🔑 YubiKey Integration**: LUKS, SSH, PAM, and GPG support with backup strategies
- **🧪 Automated Testing**: Comprehensive test suite with CI/CD integration
- **📊 Performance Monitoring**: Build optimization and health checks
- **🔒 Private Repository Support**: Template for secure work configurations

## 🚀 Quick Start

### For New Users

1. **Clone this repository**:
```bash
git clone <your-repo-url> nixos-config
cd nixos-config
```

2. **Run health checks**:
```bash
./scripts/health-check.sh
```

3. **Create your first configuration**:
```bash
# For a new host
mkdir -p hosts/home/your-hostname
cp hosts/vm/test/host.nix hosts/home/your-hostname/

# For a new user
mkdir -p homes/home/your-username
cp homes/home/adrian/home.nix homes/home/your-username/
```

4. **Build and test**:
```bash
./scripts/test-all.sh
```

### For Private/Work Configurations

1. **Create a private repository** from the template:
```bash
cp -r private-template/ ../your-private-config
cd ../your-private-config
./setup.sh
```

2. **Follow the setup prompts** to configure your private environment.

## 📁 Project Structure

```
├── flake.nix                  # Main flake configuration
├── modules/                   # System modules
│   ├── core/                  # Essential system configuration
│   ├── desktop/               # Desktop environments
│   ├── server/                # Server-specific modules
│   └── installer/             # Installation helpers
├── hosts/                     # Host configurations
│   ├── home/                  # Personal machines
│   ├── work/                  # Work machines
│   └── vm/                    # Virtual machines
├── homes/                     # User configurations
│   ├── home/                  # Personal users
│   └── work/                  # Work users
├── lib/                       # Utility functions
├── outputs/                   # Flake outputs
├── docs/                      # Documentation
├── scripts/                   # Automation scripts
└── private-template/          # Template for private repos
```

## 🔧 Configuration

### Adding a New Host

1. Create the host directory:
```bash
mkdir -p hosts/context/hostname
```

2. Create `host.nix`:
```nix
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix  # Generate with nixos-generate-config
    ../../modules/core
    ../../modules/desktop/hyprland  # Choose your desktop
  ];

  # Host-specific configuration
  networking.hostName = lib.mkDefault "hostname";
  
  # Override user passwords if needed
  users.users."username".hashedPasswordFile = lib.mkForce "/path/to/password";
}
```

### Adding a New User

1. Create the user directory:
```bash
mkdir -p homes/context/username
```

2. Create `home.nix`:
```nix
{ lib, pkgs, username, homeDirectory, ... }:
{
  home = {
    inherit username homeDirectory;
    stateVersion = "25.05";
  };

  # User-specific packages and configuration
  home.packages = with pkgs; [
    firefox
    git
  ];
}
```

### Desktop Environments

Choose your desktop environment in the host configuration:

- **Hyprland**: `../../modules/desktop/hyprland`
- **GNOME**: `../../modules/desktop/gnome`
- **KDE**: `../../modules/desktop/kde`
- **DWM**: `../../modules/desktop/dwm`

## 🔐 Secrets Management

This configuration uses **co-located secrets** - secrets are stored alongside the configurations that use them:

- **Host secrets**: `hosts/context/hostname/secrets.nix` (WiFi, VPN, system credentials)
- **User secrets**: `homes/context/username/secrets.nix` (SSH keys, API tokens, personal credentials)

### Setting Up Secrets

1. **Install agenix**:
```bash
nix profile install github:ryantm/agenix
```

2. **Create host secrets**:
```bash
# In your host directory, e.g., hosts/home/legion/
agenix -e secrets.nix
```

3. **Create user secrets**:
```bash
# In your user directory, e.g., homes/home/adrian/
agenix -e secrets.nix
```

4. **Use in configuration**:
```nix
# hosts/home/legion/host.nix
{
  age.secrets = import ./secrets.nix;
  
  # Use the secrets
  networking.wireless.networks."MyWiFi".pskFile = config.age.secrets."wifi-password".path;
}
```

See [docs/secrets-management.md](docs/secrets-management.md) for detailed setup instructions.

## 🧪 Testing & Validation

### Run All Tests
```bash
./scripts/test-all.sh
```

### Specific Tests
```bash
./scripts/test-all.sh syntax    # Syntax validation
./scripts/test-all.sh build     # Build tests
./scripts/test-all.sh vm        # VM tests
./scripts/health-check.sh       # Health checks
```

### VM Testing
```bash
./scripts/test-vm.sh           # Interactive VM testing
```

## 🚀 Building & Deployment

### Build a configuration
```bash
nix build .#nixosConfigurations.hostname
```

### Build home-manager configuration
```bash
nix build .#homeConfigurations.username-context
```

### Switch to configuration
```bash
sudo nixos-rebuild switch --flake .#hostname
```

### Apply home-manager
```bash
home-manager switch --flake .#username-context
```

## 📊 Performance & Optimization

The configuration includes build optimization features:

- **Binary caching** with Cachix integration
- **Remote builders** for distributed builds
- **Garbage collection** automation
- **Performance monitoring** and metrics

Enable in your configuration:
```nix
{
  imports = [ ./modules/build-optimization.nix ];
}
```

## � Health Monitoring

Regular health checks ensure system reliability:

```bash
./scripts/health-check.sh all        # Full health check
./scripts/health-check.sh discovery  # Auto-discovery check
./scripts/health-check.sh secrets    # Secrets management check
```

## 📖 Documentation

- **[Customisation Guide](docs/customisation.md)** - How to customize the configuration
- **[Private Config Setup](docs/private-config.md)** - Setting up private repositories
- **[Architecture Overview](docs/architecture.md)** - System architecture and diagrams
- **[Secrets Management](docs/secrets-management.md)** - Co-located secrets setup and best practices
- **[YubiKey Guides](docs/)** - Complete YubiKey integration documentation
- **[VM Testing](docs/vm-testing.md)** - Virtual machine testing procedures

## 🔄 CI/CD Integration

The project includes GitHub Actions workflows for:

- **Continuous Integration**: Automated testing and validation
- **Security Scanning**: Code quality and security checks
- **Performance Testing**: Build time monitoring
- **Documentation**: Markdown linting and link checking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./scripts/test-all.sh`
5. Submit a pull request

## 📄 License

This configuration framework is open source. See individual components for their specific licenses.

## 🆘 Troubleshooting

### Common Issues

1. **Build failures**: Run `./scripts/health-check.sh` to identify issues
2. **Import errors**: Ensure all imports use root-relative paths (`./`)
3. **User conflicts**: Check that usernames follow the context-aware naming pattern
4. **Secrets issues**: Verify agenix keys are properly configured

### Getting Help

- Check the [documentation](docs/) for detailed guides
- Run health checks for system diagnostics
- Review test output for specific error messages
- Consult the architecture diagrams for system understanding

## 🔄 Updates

Keep your configuration up to date:

```bash
nix flake update                    # Update inputs
./scripts/test-all.sh               # Validate changes
./scripts/health-check.sh           # Check system health
```
