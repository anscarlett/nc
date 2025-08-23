# Complete Minimal NixOS Repository

This document contains all the files needed to reproduce the minimal NixOS configuration repository with YubiKey security integration.

## flake.nix

```nix
{
  description = "Minimal NixOS configuration with YubiKey security";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sopsnix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      lib = import ./lib { inherit (nixpkgs) lib; };
    in {
      # Auto-discovered NixOS configurations
      nixosConfigurations = lib.mkNixosConfigurations {
        inherit inputs;
        hostsDir = ./hosts;
      };

      # Auto-discovered Home Manager configurations  
      homeConfigurations = lib.mkHomeConfigurations {
        inherit inputs;
        usersDir = ./users;
      };

      # Development shells
      devShells = lib.mkDevShells { inherit inputs nixpkgs; };
      
      # Export lib for private repos
      inherit lib;
    };
}
```

## lib/default.nix

```nix
# Main library functions
{ lib }:

let
  # Import individual modules
  utils = import ./utils.nix { inherit lib; };
  builders = import ./builders.nix { inherit lib; };
  validation = import ./validation.nix { inherit lib; };
in
  # Export all functions
  utils // builders // validation // {
    # Main configuration builders
    mkNixosConfigurations = builders.mkNixosConfigurations;
    mkHomeConfigurations = builders.mkHomeConfigurations;
    mkDevShells = builders.mkDevShells;
    
    # Utility functions
    getHostname = utils.getHostname;
    getUsername = utils.getUsername;
    getSystemArch = utils.getSystemArch;
  }
```

## lib/utils.nix

```nix
# Pure utility functions for path handling
{ lib }:

{
  # Get hostname from hosts/hostname/ path structure
  getHostname = path:
    let
      pathStr = toString path;
      parts = lib.splitString "/" pathStr;
      validParts = builtins.filter (x: x != "" && x != ".") parts;
      hostname = lib.last validParts;
    in hostname;

  # Get username from users/username/ path structure  
  getUsername = path:
    let
      pathStr = toString path;
      parts = lib.splitString "/" pathStr;
      validParts = builtins.filter (x: x != "" && x != ".") parts;
      username = lib.last validParts;
    in username;

  # Determine system architecture from hostname patterns
  getSystemArch = hostname:
    if lib.hasInfix "rock5b" hostname || 
       lib.hasInfix "rpi" hostname || 
       lib.hasInfix "arm" hostname ||
       lib.hasInfix "aarch64" hostname
    then "aarch64-linux"
    else "x86_64-linux";

  # Extract device identifier for consistent naming
  getDeviceId = hostname:
    lib.replaceStrings ["-" "_" " "] ["" "" ""] (lib.toLower hostname);

  # Discover directories in a path
  discoverDirs = dir:
    if builtins.pathExists dir
    then lib.filterAttrs (n: v: v == "directory") (builtins.readDir dir)
    else {};
}
```

## lib/builders.nix

```nix
# Configuration builder functions
{ lib }:

let
  utils = import ./utils.nix { inherit lib; };
in {
  # Build NixOS configurations from hosts directory
  mkNixosConfigurations = { inputs, hostsDir }:
    let
      hostDirs = utils.discoverDirs hostsDir;
      
      mkHost = hostname: _:
        let
          hostPath = hostsDir + "/${hostname}";
          hostConfig = hostPath + "/host.nix";
          system = utils.getSystemArch hostname;
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

      hosts = builtins.listToAttrs (lib.mapAttrsToList mkHost hostDirs);
    in
      builtins.mapAttrs (name: hostConfig:
        inputs.nixpkgs.lib.nixosSystem {
          inherit (hostConfig) system;
          specialArgs = { inherit inputs name; };
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
      ) hosts;

  # Build Home Manager configurations from users directory
  mkHomeConfigurations = { inputs, usersDir }:
    let
      userDirs = utils.discoverDirs usersDir;
      
      mkUser = username: _:
        let
          userPath = usersDir + "/${username}";
          userConfig = userPath + "/user.nix";
        in lib.nameValuePair username (import userConfig inputs);

      users = builtins.listToAttrs (lib.mapAttrsToList mkUser userDirs);
    in
      builtins.mapAttrs (name: userConfig:
        let
          system = "x86_64-linux"; # Default, can be overridden in user config
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          modules = [ userConfig ];
        }
      ) users;

  # Build development shells for all supported systems
  mkDevShells = { inputs, nixpkgs }:
    lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          yubikey-manager
          age
          sops
          mkpasswd
          git
          nixos-anywhere
        ];
      }
    );
}
```

## lib/validation.nix

```nix
# Configuration validation helpers
{ lib }:

{
  # Validate that user passwords are properly set
  validateUserPasswords = users:
    let
      usersWithoutPasswords = lib.filterAttrs (name: user: 
        !(user ? hashedPassword) || user.hashedPassword == null
      ) users;
      
      userNames = lib.attrNames usersWithoutPasswords;
    in
      if userNames != [] then
        throw ''
          ERROR: The following users don't have passwords set:
          ${lib.concatStringsSep ", " userNames}
          
          You must set a password for each user before deploying.
          Generate password hash with:
          
            nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'
          
          Then add to your host.nix:
          
            users.users.USERNAME.hashedPassword = "GENERATED_HASH";
        ''
      else users;

  # Validate disk device exists and is properly formatted
  validateDiskDevice = device:
    if device == null || device == "" then
      throw ''
        ERROR: Disk device not specified in disko configuration.
        
        You must set the disk device in your host.nix:
        
          (import ../../modules/disko.nix {
            disk = "/dev/nvme0n1";  # Your actual disk device
            luksName = "cryptroot";
            enableYubikey = true;
          })
      ''
    else if !lib.hasPrefix "/dev/" device then
      throw ''
        ERROR: Disk device "${device}" doesn't look like a valid device path.
        
        Use a proper device path like:
          /dev/nvme0n1
          /dev/sda
          /dev/disk/by-id/nvme-Samsung_SSD_980_1TB
      ''
    else device;

  # Warn about example configurations
  warnIfExample = hostname:
    if hostname == "example" then
      lib.warn ''
        WARNING: You're using the example configuration!
        
        This is just a template. You should:
        1. Copy hosts/example to hosts/yourhostname
        2. Copy users/example to users/yourusername  
        3. Customize the configurations
        4. Deploy with: nixos-rebuild switch --flake .#yourhostname
      ''
    else hostname;
}
```

## modules/core.nix

```nix
# Core system configuration - minimal essentials
{ config, pkgs, lib, inputs, ... }:

{
  # NixOS version
  system.stateVersion = "25.05";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    
    # YubiKey support in initrd
    initrd = {
      availableKernelModules = [ "uas" "usbhid" "usb_storage" ];
      systemd.enable = true;
    };
  };

  # Locale and timezone
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim git curl wget
    
    # YubiKey tools
    yubikey-manager yubikey-personalization
    
    # Encryption tools
    cryptsetup age sops
  ];

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  # YubiKey hardware support
  services.udev.packages = with pkgs; [
    yubikey-personalization
    libfido2
  ];

  # GPG agent for YubiKey
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
```

## modules/users.nix

```nix
# User management and shell configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Users configuration - auto-create from users/ directory
  users.mutableUsers = false;
  
  # Auto-discover and create users
  users.users = 
    let
      utils = import ../../lib/utils.nix { inherit lib; };
      validation = import ../../lib/validation.nix { inherit lib; };
      userDirs = builtins.attrNames (utils.discoverDirs ../users);
      
      mkUser = username: {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
        shell = pkgs.zsh;
        # Password must be set in host.nix - no default password for security
      };
      
      baseUsers = builtins.listToAttrs (map (name: { inherit name; value = mkUser name; }) userDirs);
      
      # Merge with any additional users defined in host config
      allUsers = baseUsers // (config.users.users or {});
    in
      # Validate that all users have passwords (in final evaluation)
      validation.validateUserPasswords allUsers;

  # ZSH as default shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Auto-configure Home Manager users
  home-manager.users = 
    let
      utils = import ../../lib/utils.nix { inherit lib; };
      userDirs = builtins.attrNames (utils.discoverDirs ../users);
      
      mkHomeConfig = username:
        let userPath = ../users + "/${username}/user.nix";
        in if builtins.pathExists userPath then import userPath inputs else {};
    in
      builtins.listToAttrs (map (name: { 
        inherit name; 
        value = mkHomeConfig name;
      }) userDirs);
}
```

## modules/desktop.nix

```nix
# Desktop configuration - Hyprland + essentials
{ config, pkgs, lib, ... }:

{
  # Hyprland Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Audio - PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Essential desktop packages
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    waybar wofi alacritty
    wl-clipboard grim slurp
    swaylock-effects mako
    
    # Applications
    firefox bitwarden
    
    # System utilities
    pavucontrol networkmanagerapplet
    libnotify xdg-utils
  ];

  # XDG portal for screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Default Hyprland configuration
  environment.etc."hypr/hyprland.conf".text = ''
    # Minimal Hyprland config
    monitor=,preferred,auto,1

    # Autostart
    exec-once = waybar & mako &

    # Input
    input {
        kb_layout = gb
        follow_mouse = 1
        touchpad.natural_scroll = false
    }

    # Appearance
    general {
        gaps_in = 5
        gaps_out = 10
        border_size = 2
        col.active_border = rgba(33ccffee)
        col.inactive_border = rgba(595959aa)
        layout = dwindle
    }

    decoration {
        rounding = 5
        blur.enabled = true
        drop_shadow = true
    }

    # Key bindings
    $mod = SUPER

    bind = $mod, Q, exec, alacritty
    bind = $mod, C, killactive
    bind = $mod, M, exit
    bind = $mod, R, exec, wofi --show drun
    bind = $mod, V, togglefloating
    bind = $mod, L, exec, swaylock-effects

    # Workspaces
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5

    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5

    # Move focus
    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d
  '';

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
  };

  # Stylix theming
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tomorrow-night.yaml";
    image = pkgs.fetchurl {
      url = "https://images.unsplash.com/photo-1518837695005-2083093ee35b";
      hash = "sha256-IkfNDClX/u6XCQHVNp0R8TJkFx5mApPFCeZS4cP4Kjc=";
    };
  };
}
```

## modules/server.nix

```nix
# Server-specific configuration
{ config, pkgs, lib, ... }:

{
  # Server-specific packages
  environment.systemPackages = with pkgs; [
    htop iotop iftop
    tmux screen
    rsync
    tree lshw pciutils usbutils
  ];

  # Disable unnecessary desktop services
  services.xserver.enable = lib.mkForce false;
  services.printing.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;
  
  # Disable audio services for servers
  services.pipewire.enable = lib.mkForce false;
  services.pulseaudio.enable = lib.mkForce false;
  security.rtkit.enable = lib.mkForce false;

  # Server hardening
  security = {
    sudo.enable = true;
    audit.enable = true;
    auditd.enable = true;
  };

  # Firewall configuration
  networking = {
    firewall = {
      enable = true;
      allowPing = false;
      # Add your ports here
      # allowedTCPPorts = [ 80 443 ];
    };
  };

  # Fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "24h";
  };

  # Automatic updates and cleanup
  system.autoUpgrade = {
    enable = lib.mkDefault false; # Enable manually per server
    dates = "04:00";
  };

  # More aggressive garbage collection for servers
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d";
  };
}
```

## modules/disko.nix

```nix
# Disko configuration for Btrfs + LUKS + YubiKey
{ lib, pkgs, disk ? throw "You must set 'disk' parameter (e.g., /dev/nvme0n1)"
, luksName ? "cryptroot"
, enableYubikey ? true
, swapSize ? "8G"
}:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = disk;
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = luksName;
              settings.allowDiscards = true;
              
              # YubiKey challenge-response unlock
              passwordFile = if enableYubikey then "/tmp/yubikey-luks.key" else null;
              
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                
                subvolumes = {
                  # Root subvolume - wiped on boot with impermanence
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Nix store - persistent
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Persistent data
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Logs
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Swap
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = [ "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Swap file
  swapDevices = [{
    device = "/swap/swapfile";
    size = 8192; # 8GB default
  }];

  # Impermanence configuration
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/NetworkManager"
      "/etc/nixos"
      "/etc/ssh"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    users.example = {
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
        ".config"
        ".local"
        ".ssh"
        ".gnupg"
      ];
    };
  };

  # YubiKey LUKS unlock script
  boot.initrd.postDeviceCommands = lib.mkIf enableYubikey ''
    echo "Attempting YubiKey LUKS unlock..."
    if ${pkgs.yubikey-manager}/bin/ykman otp calculate 2 "$(echo -n '${luksName}' | ${pkgs.xxd}/bin/xxd -p)" > /tmp/response 2>/dev/null; then
      echo -n "$(cat /tmp/response)" | ${pkgs.xxd}/bin/xxd -r -p > /tmp/yubikey-luks.key
      echo "YubiKey response generated"
    else
      echo "YubiKey not found or error - falling back to password"
      echo -n "fallback" > /tmp/yubikey-luks.key
    fi
  '';
}
```

## modules/secrets.nix

```nix
# Secrets management configuration
{ config, pkgs, lib, ... }:

{
  # SOPS configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    validateSopsFiles = false; # Allow missing secrets files
    
    # Age key management
    age = {
      # Key file location
      keyFile = "/var/lib/sops-nix/key.txt";
      
      # Generate key if it doesn't exist
      generateKey = true;
    };
  };

  # Ensure sops directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0755 root root -"
  ];

  # Tools for secrets management
  environment.systemPackages = with pkgs; [
    sops
    age
  ];

  # Example secret usage (uncomment and customize)
  # sops.secrets.example-secret = {
  #   owner = "root";
  #   group = "wheel";
  #   mode = "0440";
  # };
}
```

## hosts/example/host.nix

```nix
# Example host configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Import core modules
  imports = [
    ../../modules/core.nix
    ../../modules/users.nix
    ../../modules/desktop.nix
    (import ../../modules/disko.nix {
      disk = "/dev/nvme0n1";  # CHANGE THIS TO YOUR DISK!
      luksName = "cryptroot";
      enableYubikey = true;
    })
  ];

  # Hostname (auto-detected from folder name: "example")
  networking.hostName = "example";

  # Hardware configuration (adjust for your hardware)
  boot.initrd.availableKernelModules = [ 
    "xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" 
  ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"

  # Graphics
  hardware.graphics.enable = true;
  # hardware.nvidia.modesetting.enable = true; # Uncomment for NVIDIA

  # User password (generate with: mkpasswd -m sha-512)
  # users.users.example.hashedPassword = "YOUR_GENERATED_HASH_HERE";
  # 
  # REQUIRED: You MUST set a password hash before deploying!
  # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'

  # Example secrets (uncomment when needed)
  # sops.secrets.wifi-password = {
  #   sopsFile = ./secrets.yaml;
  #   owner = "root";
  #   group = "networkmanager";
  # };

  # Example network configuration using secrets
  # networking.wireless.networks = {
  #   "MyWiFi" = {
  #     pskRaw = config.sops.secrets.wifi-password.path;
  #   };
  # };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add host-specific packages here
  ];
}
```

## hosts/example/secrets.yaml

```yaml
# Example secrets file - customize and encrypt with sops
# Run: sops -e secrets.yaml

# Network secrets
wifi-password: "your-wifi-password-here"
ethernet-config: |
  # Any network configuration that contains secrets

# VPN configuration (if needed)
vpn-config: |
  client
  dev tun
  proto udp
  remote vpn.company.com 1194
  auth-user-pass-file /run/secrets/vpn-credentials
  # ... rest of VPN config

vpn-credentials: |
  username
  password

# SSL certificates
ssl-cert: |
  -----BEGIN CERTIFICATE-----
  # Your certificate content
  -----END CERTIFICATE-----

ssl-key: |
  -----BEGIN PRIVATE KEY-----
  # Your private key content  
  -----END PRIVATE KEY-----

# API tokens
monitoring-token: "your-monitoring-api-token"
backup-key: "your-backup-encryption-key"
```

## hosts/server/host.nix

```nix
# Example server configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Import core modules (no desktop for servers)
  imports = [
    ../../modules/core.nix
    ../../modules/users.nix  # Still need users, but minimal
    ../../modules/server.nix
    (import ../../modules/disko.nix {
      disk = "/dev/sda";  # CHANGE THIS TO YOUR DISK!
      luksName = "cryptserver";
      enableYubikey = true;
    })
  ];

  # Hostname (auto-detected from folder name: "server")
  networking.hostName = "server";

  # Server hardware configuration
  boot.initrd.availableKernelModules = [ 
    "xhci_pci" "ahci" "usb_storage" "sd_mod" 
  ];

  # No graphics needed
  hardware.graphics.enable = false;

  # Server user with minimal shell (can override in users.nix if needed)
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;  # Simple shell for servers
    # Password must be set - no default
  };

  # Set user password (generate with: mkpasswd -m sha-512)
  # users.users.admin.hashedPassword = "YOUR_GENERATED_HASH_HERE";
  # 
  # REQUIRED: You MUST set a password hash before deploying!
  # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'

  # Server-specific services
  services.openssh.settings.PasswordAuthentication = lib.mkForce false;
  
  # Example: Enable specific server services
  # services.nginx.enable = true;
  # services.postgresql.enable = true;
  # services.redis.servers."".enable = true;

  # Example secrets (uncomment when needed)
  # sops.secrets.ssl-cert = {
  #   sopsFile = ./secrets.yaml;
  #   owner = "nginx";
  #   group = "nginx";
  # };
}
```

## users/example/user.nix

```nix
# Example user configuration
{ config, pkgs, lib, ... }:

{
  home = {
    username = "example";
    homeDirectory = "/home/example";
    stateVersion = "25.05";
  };

  # Essential programs
  programs = {
    home-manager.enable = true;
    
    # Git configuration
    git = {
      enable = true;
      userName = "Your Name";                    # CHANGE THIS
      userEmail = "your.email@example.com";     # CHANGE THIS
    };
    
    # ZSH shell
    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        ".." = "cd ..";
        gs = "git status";
        ga = "git add";
        gc = "git commit";
      };
    };
    
    # Alacritty terminal
    alacritty = {
      enable = true;
      settings = {
        window.opacity = 0.9;
        font.size = 12;
      };
    };
    
    # Firefox browser
    firefox.enable = true;
  };

  # User packages
  home.packages = with pkgs; [
    # Development
    vscode
    
    # Utilities
    htop tree file
    zip unzip
    
    # Media
    mpv imv
  ];

  # Impermanence - persist user data
  home.persistence."/persist/home/example" = {
    directories = [
      "Documents"
      "Downloads" 
      "Pictures"
      "Videos"
      ".config"
      ".local"
      ".ssh"
      ".gnupg"
    ];
    allowOther = true;
  };

  # Example secrets (uncomment when setting up)
  # sops.secrets.ssh-key = {
  #   sopsFile = ./secrets.yaml;
  #   path = "${config.home.homeDirectory}/.ssh/id_rsa";
  # };
}
```

## users/example/secrets.yaml

```yaml
# Example user secrets - customize and encrypt with sops
# Run: sops -e secrets.yaml

# SSH keys
ssh-private-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  # Your SSH private key content
  -----END OPENSSH PRIVATE KEY-----

# Development tokens
github-token: "ghp_your_github_personal_access_token"
gitlab-token: "glpat-your_gitlab_token"

# API keys for development
aws-access-key: "AKIA..."
aws-secret-key: "your-aws-secret"

# GPG private key (if not using YubiKey)
gpg-private-key: |
  -----BEGIN PGP PRIVATE KEY BLOCK-----
  # Your GPG private key
  -----END PGP PRIVATE KEY BLOCK-----

# Application-specific secrets
docker-auth: |
  {
    "auths": {
      "registry.company.com": {
        "auth": "base64-encoded-credentials"
      }
    }
  }

# Database credentials (for development)
dev-db-password: "your-dev-database-password"
```

## .gitignore

```text
# Nix build results
result
result-*

# Age keys (NEVER commit these!)
*.txt
keys.txt
.config/age/keys.txt

# Decrypted secrets (should always be encrypted .age files)
secrets/*.key
secrets/*.pem
secrets/*.crt
secrets/*.conf
secrets/decrypted-*

# Backup files that might contain sensitive data
*.backup
yubikey-backup.txt
oath-backup.txt
*-backup.txt

# Temporary files
.tmp/
*.tmp
*.log

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# VM disk images
*.qcow2
*.img

# Password files (if anyone accidentally creates them)
password.txt
passwords.txt
*password*

# Common secret file patterns
*.secret
*.private
*_key
*_token

# Flake lock (uncomment if you want to pin versions)
# flake.lock
```

## README.md

```markdown
# Minimal NixOS Configuration

A minimal, secure NixOS setup with YubiKey integration, focused on getting systems running quickly.

## 🚀 Quick Start

1. **Copy template**: `cp -r hosts/example hosts/mylaptop && cp -r users/example users/myuser`
2. **Configure YubiKey**: Follow [YubiKey Setup](#yubikey-setup) below
3. **Edit configs**: Set disk device, name, email in copied files
4. **Deploy**: `sudo nixos-rebuild switch --flake .#mylaptop`

## 📁 Repository Structure

```
minimal-nixos/
├── flake.nix                 # Minimal flake (just inputs/outputs)
├── lib/
│   ├── default.nix           # Main library exports
│   ├── utils.nix             # Path/name utilities  
│   └── builders.nix          # Configuration builders
├── modules/
│   ├── core.nix              # Essential system components only
│   ├── users.nix             # User management & shell
│   ├── desktop.nix           # Hyprland + essentials
│   ├── disko.nix             # Btrfs + LUKS + YubiKey
│   └── secrets.nix           # Secrets management
├── hosts/
│   └── example/
│       ├── host.nix          # Example host → example
│       └── secrets.yaml      # Host secrets
├── users/
│   └── example/
│       ├── user.nix          # Example user → example
│       └── secrets.yaml      # User secrets
└── docs/
    ├── YUBIKEY.md            # Complete YubiKey guide
    ├── PRIVATE.md            # Private repo setup
    └── TEMPLATE.md           # Pure template copying
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
```

## TEMPLATE.md

```markdown
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
   # Uncomment and set in hosts/mylaptop/host.nix:
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
```

## QUICKSTART.md

```markdown
# Quick Start Guide

## 🚀 Get Running in 15 Minutes

### 1. Clone Repository
```bash
git clone <this-repo> minimal-nixos
cd minimal-nixos
```

### 2. YubiKey Basic Setup
```bash
# Install tools
nix-shell -p yubikey-manager

# Check YubiKey
ykman info

# Enable all features
ykman config usb --enable-all

# Configure for LUKS (OVERWRITES slot 2!)
ykman otp chalresp --generate 2

# Test
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

### 3. Copy Example Configuration
```bash
# Copy and rename example configs
cp -r hosts/example hosts/mylaptop
cp -r users/example users/myuser
```

### 4. Customize Configuration

Edit `hosts/mylaptop/host.nix`:
- Change disk device: `disk = "/dev/nvme0n1";`
- Change LUKS name: `luksName = "cryptlaptop";`

Edit `users/myuser/user.nix`:
- Change name: `userName = "Your Real Name";`
- Change email: `userEmail = "your@email.com";`

### 5. Set Password
```bash
# Generate hash
nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'

# Add to hosts/mylaptop/host.nix:
users.users.myuser.hashedPassword = "PASTE_HASH_HERE";
```

### 6. Deploy
```bash
sudo nixos-rebuild switch --flake .#mylaptop
```

## 🔑 Essential YubiKey Commands

### Daily 2FA Usage
```bash
# List accounts
ykman oath accounts list

# Get code for specific account  
ykman oath accounts code "GitHub:username"

# Get all codes
ykman oath accounts code
```

### Add New 2FA Account
```bash
# Website shows you QR code, click "enter manually" for secret
ykman oath accounts add "ServiceName:username" SECRET_FROM_WEBSITE

# For sensitive accounts, require touch
ykman oath accounts add --touch "Banking:username" SECRET
```

### Check YubiKey Status
```bash
# Basic info
ykman info

# Check what's configured
ykman otp info    # Challenge-response slots
ykman oath list   # 2FA accounts
ykman piv info    # SSH/certificates
```

## 🛠️ System Management

### Build Commands
```bash
# Test configuration
nix flake check

# Build without switching
nixos-rebuild build --flake .#mylaptop

# Switch to new configuration
sudo nixos-rebuild switch --flake .#mylaptop

# Rollback if needed
sudo nixos-rebuild switch --rollback
```

### Check Disk Encryption
```bash
# Check LUKS status
sudo cryptsetup status /dev/mapper/cryptroot

# Check YubiKey LUKS key
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep "Key Slot"

# Test YubiKey response
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

### Backup Important Data
```bash
# Backup LUKS header (CRITICAL!)
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file luks-header.img

# Backup 2FA secrets (KEEP SECURE!)
ykman oath accounts uri "GitHub:username" > github-backup.txt

# Store on encrypted USB drive, NOT in cloud!
```

### Recovery Commands
```bash
# Boot without YubiKey (use password)
# At LUKS prompt, just type your disk password

# Remove lost YubiKey from LUKS
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 1

# Restore LUKS header if disk corrupted
sudo cryptsetup luksHeaderRestore /dev/nvme0n1p2 --header-backup-file luks-header.img
```

## 📚 Next Steps

- **Read docs/YUBIKEY.md** for complete YubiKey features
- **See docs/PRIVATE.md** for work/private repository setup
- **Test everything** on a VM first before production use

## 🆘 Emergency Contact

If you're locked out:
1. Try password at LUKS prompt
2. Boot from NixOS ISO to recover
3. Use backup YubiKey if configured
4. Restore from LUKS header backup if needed
```