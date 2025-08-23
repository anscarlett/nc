# Private Configuration Setup

This guide shows how to create a private repository that extends this public NixOS configuration while keeping work-specific configurations secure.

## 🎯 Overview

**Public Repository (this one)**: Contains general modules, home configurations, and documentation
**Private Repository**: Contains work-specific hosts and user configurations

## 🏗️ Private Repository Structure

```
my-private-nixos/
├── flake.nix              # Directly imports from public repo - no duplication!
├── hosts/ct/laptop/       # Your private hosts (auto-discovered)
├── homes/work/adrianscarlett/ # Your private users (auto-discovered)
└── secrets/               # Your work secrets
```

## 🚀 Setup Steps

### 1. Create Private Repository

Create a new private repository on GitLab/GitHub:

```bash
# Create new directory
mkdir ~/my-private-nixos
cd ~/my-private-nixos

# Initialize git
git init
git remote add origin git@gitlab.com:username/my-private-nixos.git
```

### 2. Create Flake Configuration

Create `flake.nix` that imports the public configuration:

```nix
{
  description = "Private NixOS Configuration";

  inputs = {
    # Import the public configuration
    public-config = {
      url = "github:anscarlett/nc";
      # Or if using a different branch/tag:
      # url = "github:anscarlett/nc/main";
    };
    
    # You can also override inputs from the public config
    nixpkgs.follows = "public-config/nixpkgs";
    home-manager.follows = "public-config/home-manager";
    
    # Add private-only inputs if needed
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, public-config, ... }@inputs: {
    # Combine public configurations with your private ones
    nixosConfigurations = public-config.nixosConfigurations // 
      ((import "${public-config}/outputs/nixos-configurations.nix") inputs);
    
    homeConfigurations = public-config.homeConfigurations // 
      ((import "${public-config}/outputs/home-configurations.nix") inputs);

    # Re-export useful things from public config
    lib = public-config.lib;
    modules = public-config.modules;
  };
}
```

### 3. Create Your Configurations

That's it! No copying needed. The public repo's output files will automatically discover your `hosts/` and `homes/` folders and build them using the same logic.

### 4. Create Work Host Configuration

Create `hosts/ct/laptop/host.nix`:

```nix
{ config, lib, pkgs, inputs, ... }:

{
  # Import the public core modules
  imports = [
    # Import public modules through inputs
    inputs.public-config.modules.core
    inputs.public-config.modules.desktop.gnome  # or hyprland
    
    # Add work-specific modules
    ../../../work-modules/vpn
    ../../../work-modules/corporate-ca
  ];

  # Work-specific configuration
  networking.hostName = "ct-laptop";  # Will be auto-detected as ct-laptop
  
  # Corporate VPN
  services.corporate-vpn.enable = true;
  
  # Work-specific packages
  environment.systemPackages = with pkgs; [
    teams-for-linux
    slack
    zoom-us
    # ... other work tools
  ];

  # Corporate CA certificates
  security.ca-certificates.enable = true;
  
  # Secrets management
  age.secrets.work-wifi = {
    file = ../../../secrets/work-wifi.age;
    owner = "adrianscarlett";
  };

  # User configuration
  users.users.adrianscarlett = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    passwordFile = config.age.secrets.work-password.path;
  };
}
```

### 5. Create Work Home Configuration

Create `homes/work/adrianscarlett/home.nix`:

```nix
{ config, lib, pkgs, ... }:

{
  home.username = "adrianscarlett";
  home.homeDirectory = "/home/adrianscarlett";
  
  # Import base home configuration from public repo
  imports = [
    # Reference public home modules if available
  ];

  # Work-specific home configuration
  programs.git = {
    enable = true;
    userName = "Adrian Scarlett";
    userEmail = "adrian.scarlett@company.com";
    
    # Work-specific git config
    extraConfig = {
      core.sshCommand = "ssh -i ~/.ssh/work_key";
    };
  };

  # Work SSH configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "work-server" = {
        hostname = "internal.company.com";
        user = "adrianscarlett";
        identityFile = "~/.ssh/work_key";
      };
    };
  };

  # Work-specific shell aliases
  programs.zsh.shellAliases = {
    work-vpn = "sudo systemctl start corporate-vpn";
    work-off = "sudo systemctl stop corporate-vpn";
  };

  home.stateVersion = "25.05";
}
```

## 🔐 Secrets Management

### Option 1: Using agenix

```bash
# In your private repo
nix-shell -p agenix

# Create age key
age-keygen -o ~/.config/age/keys.txt

# Add public key to secrets/secrets.nix
mkdir secrets
echo 'let
  user1 = "age1abc123..."; # Your public key
in {
  "work-wifi.age".publicKeys = [ user1 ];
  "work-password.age".publicKeys = [ user1 ];
}' > secrets/secrets.nix

# Encrypt secrets
agenix -e work-wifi.age
agenix -e work-password.age
```

### Option 2: Using sops-nix

```bash
# Install sops
nix-shell -p sops

# Create .sops.yaml
cat > .sops.yaml << EOF
keys:
  - &admin_key age1abc123...  # Your age key
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
    - age:
      - *admin_key
EOF

# Create encrypted secrets
sops secrets/work.yaml
```

## 🚀 Usage

### Building Work Configuration

```bash
# In your private repository
# Hostnames are auto-generated from folder structure:
# hosts/ct/laptop/host.nix → ct-laptop
sudo nixos-rebuild switch --flake .#ct-laptop

# Usernames are auto-generated from folder structure:  
# homes/work/adrianscarlett/home.nix → adrianscarlett-work
home-manager switch --flake .#adrianscarlett-ct
```

### Updating Public Configuration

```bash
# Update the public config input
nix flake update public-config

# Or update everything
nix flake update
```

## 🔄 Keeping in Sync

### Automatic Updates

Create `.github/workflows/update-deps.yml` or `.gitlab-ci.yml`:

```yaml
# GitLab CI example
update-deps:
  image: nixos/nix
  script:
    - nix flake update
    - git diff --exit-code || (git add . && git commit -m "Update dependencies" && git push)
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

### Manual Updates

```bash
# Update public config to latest
nix flake lock --update-input public-config

# Update specific input
nix flake lock --update-input nixpkgs
```

## 🛡️ Security Benefits

- **🔒 Secrets isolation**: Work credentials never touch public repo
- **🏢 Corporate compliance**: Keep proprietary configs private  
- **🔄 Easy updates**: Pull improvements from public config
- **🧩 Modular approach**: Extend without forking
- **👥 Team sharing**: Share private repo with work colleagues only

## 📝 Best Practices

1. **Use different SSH keys** for work and personal repos
2. **Encrypt all secrets** using agenix or sops-nix
3. **Regular updates** from the public configuration
4. **Document work-specific setup** in private repo
5. **Use corporate GitLab/GitHub** for additional security
6. **Backup encryption keys** securely

This approach gives you the best of both worlds: public modules and documentation with private work configurations!
