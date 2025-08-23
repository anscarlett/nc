# Private Repository Setup

This guide shows how to create a private repository that extends this minimal public configuration for work or personal use.

## 🎯 Why Private Repository?

- **Keep secrets safe**: Work configs, WiFi passwords, API keys
- **Corporate compliance**: Proprietary configurations
- **Personal privacy**: Your personal setup details
- **Team collaboration**: Share with colleagues securely

## 🏗️ Private Repository Structure

```
my-private-nixos/
├── flake.nix              # Imports public repo + adds private configs
├── hosts/
│   └── work-laptop/
│       ├── host.nix       # Work-specific host config
│       └── secrets.yaml   # WiFi, VPN, certificates
├── users/
│   └── work-user/
│       ├── user.nix       # Work user config  
│       └── secrets.yaml   # SSH keys, API tokens
└── modules/               # Work-specific modules (optional)
    ├── corporate-vpn.nix
    └── monitoring.nix
```

## 🚀 Setup Steps

### 1. Create Private Repository

```bash
# Create new private repo on GitLab/GitHub
# Clone it locally
git clone git@gitlab.com:company/my-private-nixos.git
cd my-private-nixos
```

### 2. Create Flake That Imports Public Config

Create `flake.nix`:

```nix
{
  description = "Private NixOS Configuration";

  inputs = {
    # Import the minimal public configuration
    public-config.url = "github:yourusername/minimal-nixos";
    
    # Inherit all inputs from public config
    nixpkgs.follows = "public-config/nixpkgs";
    home-manager.follows = "public-config/home-manager";
    disko.follows = "public-config/disko";
    impermanence.follows = "public-config/impermanence";
    stylix.follows = "public-config/stylix";
    sopsnix.follows = "public-config/sopsnix";
  };

  outputs = { self, public-config, ... }@inputs: {
    # Discover hosts from local hosts/ directory
    nixosConfigurations = 
      let
        lib = inputs.nixpkgs.lib;
        
        discoverLocalHosts = 
          let
            hostsDir = ./hosts;
            hostDirs = if builtins.pathExists hostsDir
              then lib.filterAttrs (n: v: v == "directory") (builtins.readDir hostsDir)
              else {};
            
            mkHost = hostname: _:
              let
                hostPath = hostsDir + "/${hostname}";
                hostConfig = hostPath + "/host.nix";
                system = public-config.lib.getSystemArch hostname;
              in lib.nameValuePair hostname {
                inherit system;
                modules = [ 
                  (import hostConfig inputs)
                  inputs.home-manager.nixosModules.home-manager
                  inputs.disko.nixosModules.disko
                  inputs.sopsnix.nixosModules.sops
                  inputs.impermanence.nixosModules.impermanence
                  inputs.stylix.nixosModules.stylix
                ];
              };
          in
            builtins.listToAttrs (lib.mapAttrsToList mkHost hostDirs);

        localHosts = discoverLocalHosts;
      in
        builtins.mapAttrs (name: hostConfig:
          inputs.nixpkgs.lib.nixosSystem {
            inherit (hostConfig) system;
            specialArgs = { inherit inputs; };
            modules = hostConfig.modules ++ [
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = { inherit inputs; };
                };
              }
            ];
          }
        ) localHosts;

    # Re-export lib functions
    lib = public-config.lib;
  };
}
```

### 3. Create Work Host Configuration

Create `hosts/work-laptop/host.nix`:

```nix
# Work laptop configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Import public modules  
  imports = [
    # Use the core and desktop from public repo
    "${inputs.public-config}/modules/core.nix"
    "${inputs.public-config}/modules/desktop.nix"
    
    # Disko configuration
    (import "${inputs.public-config}/modules/disko.nix" {
      disk = "/dev/nvme0n1";  # Your work laptop disk
      luksName = "cryptwork";
      enableYubikey = true;
    })
  ];

  # Hostname automatically detected as "work-laptop"
  networking.hostName = "work-laptop";

  # Work-specific packages
  environment.systemPackages = with pkgs; [
    teams-for-linux
    slack  
    zoom-us
    # Add other work tools
  ];

  # User password
  users.users.work-user.hashedPassword = "YOUR_GENERATED_HASH";

  # Secrets management
  sops.defaultSopsFile = ./secrets.yaml;
  
  # Example: WiFi with secret password
  sops.secrets.work-wifi-password = {
    owner = "root";
    group = "networkmanager";
  };
  
  networking.wireless.networks."CompanyWiFi" = {
    pskRaw = config.sops.secrets.work-wifi-password.path;
  };
}
```

### 4. Create Work User Configuration

Create `users/work-user/user.nix`:

```nix
# Work user configuration  
{ config, pkgs, lib, inputs, ... }:

{
  home = {
    username = "work-user";
    homeDirectory = "/home/work-user";
    stateVersion = "25.05";
  };

  programs = {
    home-manager.enable = true;
    
    git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.name@company.com";
      
      # Sign commits with YubiKey (after GPG setup)
      signing = {
        signByDefault = true;
        key = "YOUR_GPG_KEY_ID";
      };
    };
    
    ssh = {
      enable = true;
      matchBlocks = {
        "work-server" = {
          hostname = "internal.company.com";
          user = "work-user";
          identityFile = "~/.ssh/work_key";
        };
      };
    };
  };

  # Work-specific packages
  home.packages = with pkgs; [
    postman
    docker-compose
    kubectl
  ];

  # Secrets for user
  sops.secrets.ssh-work-key = {
    sopsFile = ./secrets.yaml;
    path = "${config.home.homeDirectory}/.ssh/work_key";
  };
  
  # Persist important directories
  home.persistence."/persist/home/work-user" = {
    directories = [
      "Documents/Work"
      "Projects"
      ".config/Code"
      ".docker"
    ];
    allowOther = true;
  };
}
```

### 5. Set Up Secrets

#### Generate Keys
```bash
# Generate age key for encryption
nix-shell -p age --run 'age-keygen -o ~/.config/age/keys.txt'

# Show your public key
grep "public key:" ~/.config/age/keys.txt
```

#### Create Secrets Files

Create `hosts/work-laptop/secrets.yaml`:
```yaml
# Work laptop system secrets
work-wifi-password: "your-wifi-password"
vpn-config: |
  # Your VPN configuration
  client
  dev tun
  proto udp
  # ... rest of config
```

Create `users/work-user/secrets.yaml`:
```yaml
# Work user secrets
ssh-work-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  # Your SSH private key content
  -----END OPENSSH PRIVATE KEY-----
github-token: "ghp_your_github_token"
```

#### Configure SOPS
Create `.sops.yaml`:
```yaml
keys:
  - &work-user age1abc123your-age-public-key-here

creation_rules:
  - path_regex: hosts/work-laptop/secrets\.yaml$
    key_groups:
      - age:
          - *work-user
  - path_regex: users/work-user/secrets\.yaml$
    key_groups:
      - age:
          - *work-user
```

#### Encrypt Secrets
```bash
# Encrypt host secrets
nix-shell -p sops --run 'sops -e hosts/work-laptop/secrets.yaml'

# Encrypt user secrets  
nix-shell -p sops --run 'sops -e users/work-user/secrets.yaml'
```

### 6. Deploy Private Configuration

```bash
# Build and switch to your work configuration
sudo nixos-rebuild switch --flake .#work-laptop

# Build home manager
home-manager switch --flake .#work-user
```

## 🔄 Keeping Up to Date

### Update Public Configuration
```bash
# Update the public repo input
nix flake update public-config

# Deploy updates
sudo nixos-rebuild switch --flake .#work-laptop
```

### Add New Features
Since you're importing modules from the public repo, you automatically get:
- Security updates
- New module features  
- Bug fixes
- Documentation improvements

You can override or extend anything in your private configs.

## 🛡️ Security Considerations

### What to Keep Private
- **SSH private keys** - Never commit unencrypted
- **API tokens** - Use sops/age encryption
- **Passwords** - Always encrypted
- **VPN configurations** - Often contain secrets
- **Corporate certificates** - Company intellectual property

### What's Safe to Share
- **Public keys** - SSH, GPG public keys are safe
- **Configuration structure** - Module imports and options
- **Package lists** - What software you use
- **Non-sensitive settings** - Timezone, locale, etc.

### Secrets Management Best Practices
```bash
# Always encrypt secrets before committing
sops -e secrets.yaml

# Never commit .age keys or decrypted files
echo "*.txt" >> .gitignore
echo ".config/age/keys.txt" >> .gitignore

# Use descriptive secret names
work-wifi-password  # Good
secret1            # Bad
```

## 🔧 Advanced Private Repository Features

### Custom Modules
Create `modules/corporate-vpn.nix`:
```nix
{ config, pkgs, lib, ... }:

{
  # Custom corporate VPN module
  services.openvpn.servers.corporate = {
    config = config.sops.secrets.vpn-config.path;
    autoStart = false;
  };
  
  environment.systemPackages = with pkgs; [
    openvpn
  ];
}
```

### Multiple Environments
```
hosts/
├── work-laptop/     # Work laptop
├── work-desktop/    # Work desktop  
├── home-laptop/     # Personal laptop
└── server/          # Home server

users/
├── work-user/       # Work identity
├── personal-user/   # Personal identity
└── admin-user/      # Server admin
```

### Team Sharing
```yaml
# .sops.yaml with multiple team members
keys:
  - &user1 age1abc123...
  - &user2 age1def456...
  - &user3 age1ghi789...

creation_rules:
  - path_regex: \.yaml$
    key_groups:
      - age:
          - *user1
          - *user2
          - *user3
```

## 📋 Migration Checklist

When moving from public to private:

- [ ] **Copy configurations** from public repo
- [ ] **Update personal details** (name, email, etc.)
- [ ] **Set up secrets encryption** (age/sops)
- [ ] **Configure work-specific services**
- [ ] **Test deployment** on non-production first
- [ ] **Document work-specific setup** for team
- [ ] **Set up CI/CD** for automatic updates (optional)

## 🚨 Emergency Access

### If Private Repo is Inaccessible
1. **Use public repo** for basic system recovery
2. **Deploy minimal config**: `sudo nixos-rebuild switch --flake github:yourusername/minimal-nixos#example`
3. **Fix private repo access** then redeploy

### If Age Keys are Lost
1. **Generate new age identity**
2. **Re-encrypt all secrets** with new key
3. **Update .sops.yaml** with new public key
4. **Commit and deploy** updated configs

This approach gives you the benefits of public modules with private customization and security!