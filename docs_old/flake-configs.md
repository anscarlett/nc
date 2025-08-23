# flake.nix

```nix
{
  description = "NC - Personal NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hardware-specific configurations
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    # Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Additional flakes
    nur.url = "github:nix-community/NUR";
    
    # Plasma manager for KDE
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, nixos-hardware, lanzaboote, disko, agenix, nur, plasma-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      
      # Import library functions for auto-discovery
      lib = import ./lib { lib = nixpkgs.lib; };
      
      # Overlay for stable packages
      overlays = [
        (final: prev: {
          stable = import nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
        })
        nur.overlay
      ];
      
      # Common arguments passed to all configurations
      commonArgs = {
        inherit inputs system;
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      };
      
      # Auto-discover hosts from the hosts directory
      hosts = lib.mkConfigs.mkHosts ./hosts;
      
      # Auto-discover home configurations from the homes directory (if it exists)
      homes = if builtins.pathExists ./homes 
        then lib.mkConfigs.mkHomes ./homes
        else {};
      
      # Helper function to create NixOS configuration from auto-discovered hosts
      mkNixosConfiguration = hostName: hostConfig: nixpkgs.lib.nixosSystem {
        inherit (hostConfig) system;
        
        specialArgs = commonArgs;
        
        modules = [
          # Core modules
          ./modules/nixos
          
          # Input modules
          agenix.nixosModules.default
          disko.nixosModules.disko
          lanzaboote.nixosModules.lanzaboote
          
          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = commonArgs;
              sharedModules = [
                ./modules/home-manager
                plasma-manager.homeManagerModules.plasma-manager
              ];
            };
          }
          
          # Host-specific configuration (auto-discovered)
          (hostConfig inputs)
          
          # Common configuration
          {
            system.stateVersion = "24.05";
            nixpkgs.overlays = overlays;
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };
      
      # Helper function to create standalone Home Manager configuration
      mkHomeConfiguration = homeName: homeConfig: home-manager.lib.homeManagerConfiguration {
        pkgs = commonArgs.pkgs;
        extraSpecialArgs = commonArgs;
        
        modules = [
          ./modules/home-manager
          (homeConfig inputs)
          plasma-manager.homeManagerModules.plasma-manager
          {
            home.stateVersion = "24.05";
          }
        ];
      };
      
    in {
      # Auto-generated NixOS configurations from hosts directory
      nixosConfigurations = builtins.mapAttrs mkNixosConfiguration hosts;
      
      # Auto-generated Home Manager configurations from homes directory (if exists)
      homeConfigurations = builtins.mapAttrs mkHomeConfiguration homes;
      
      # Development shells
      devShells.${system} = {
        default = commonArgs.pkgs.mkShell {
          name = "nixos-config";
          packages = with commonArgs.pkgs; [
            # Nix tools
            nixos-rebuild
            home-manager
            nix-output-monitor
            nvd
            
            # System tools
            git
            vim
            
            # Deployment tools
            deploy-rs
            
            # Disk management
            parted
            
            # Security tools
            age
            agenix.packages.${system}.default
          ];
        };
        
        python = commonArgs.pkgs.mkShell {
          name = "python-dev";
          packages = with commonArgs.pkgs; [
            python311
            python311Packages.pip
            python311Packages.virtualenv
            poetry
          ];
        };
        
        rust = commonArgs.pkgs.mkShell {
          name = "rust-dev";
          packages = with commonArgs.pkgs; [
            rustc
            cargo
            rustfmt
            clippy
            rust-analyzer
          ];
        };
      };
      
      # Custom packages
      packages.${system} = {
        # Custom deployment script that auto-detects available hosts
        deploy = commonArgs.pkgs.writeShellScriptBin "deploy" ''
          set -e
          
          if [ $# -eq 0 ]; then
            echo "Usage: deploy <hostname>"
            echo "Available hosts:"
            ${builtins.concatStringsSep "\n" (map (host: "echo \"  - ${host}\"") (builtins.attrNames hosts))}
            exit 1
          fi
          
          HOST=$1
          echo "Deploying to $HOST..."
          
          # Check if host exists
          if ! nix eval .#nixosConfigurations.$HOST.config.system.build.toplevel >/dev/null 2>&1; then
            echo "Error: Host '$HOST' not found in configuration"
            echo "Available hosts:"
            ${builtins.concatStringsSep "\n" (map (host: "echo \"  - ${host}\"") (builtins.attrNames hosts))}
            exit 1
          fi
          
          nixos-rebuild switch --flake .#$HOST --target-host $HOST --use-remote-sudo
        '';
        
        # System update script
        update = commonArgs.pkgs.writeShellScriptBin "update" ''
          set -e
          
          echo "Updating flake inputs..."
          nix flake update
          
          echo "Building system..."
          nixos-rebuild build --flake .
          
          echo "System updated successfully!"
        '';
        
        # List available configurations
        list-configs = commonArgs.pkgs.writeShellScriptBin "list-configs" ''
          echo "Available NixOS configurations:"
          ${builtins.concatStringsSep "\n" (map (host: "echo \"  - ${host}\"") (builtins.attrNames hosts))}
          
          ${if homes != {} then ''
            echo ""
            echo "Available Home Manager configurations:"
            ${builtins.concatStringsSep "\n" (map (home: "echo \"  - ${home}\"") (builtins.attrNames homes))}
          '' else ""}
        '';
      };
      
      # Formatters
      formatter.${system} = commonArgs.pkgs.nixpkgs-fmt;
      
      # Apps
      apps.${system} = {
        deploy = {
          type = "app";
          program = "${self.packages.${system}.deploy}/bin/deploy";
        };
        
        update = {
          type = "app";
          program = "${self.packages.${system}.update}/bin/update";
        };
        
        list-configs = {
          type = "app";
          program = "${self.packages.${system}.list-configs}/bin/list-configs";
        };
      };
      
      # Export lib and modules for use by private configs
      lib = import ./lib { lib = nixpkgs.lib; };
      modules = {
        nixos = ./modules/nixos;
        home-manager = ./modules/home-manager;
        disko-presets = ./modules/disko-presets;
      };
    };
}
        deploy = {
          type = "app";
          program = "${self.packages.${system}.deploy}/bin/deploy";
        };
        
        update = {
          type = "app";
          program = "${self.packages.${system}.update}/bin/update";
        };
      };
    };
}
```

# hosts/work-laptop/default.nix

```nix
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];
  
  # System configuration
  mySystem = {
    # Core system
    system = {
      enable = true;
      stateVersion = "24.05";
    };
    
    # Boot configuration
    boot = {
      loader = "systemd-boot";
      secureBoot.enable = true;
    };
    
    # Networking
    networking = {
      enable = true;
      hostName = "work-laptop";
      wifi.enable = true;
      vpn.enable = true;
      firewall.enable = true;
    };
    
    # Users
    users = {
      enable = true;
      mainUser = "user";
      users.user = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "docker" "libvirtd" ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          # Add your SSH public keys here
        ];
      };
    };
    
    # Desktop environment
    desktop = {
      enable = true;
      environment = "gnome";
    };
    
    # Hardware
    hardware = {
      enable = true;
      type = "laptop";
    };
    
    # Security
    security = {
      enable = true;
      yubikey = {
        enable = true;
        pam.enable = true;
        gpg.enable = true;
        ssh.enable = true;
        u2f.enable = true;
      };
      hardening = {
        enable = true;
        level = "standard";
      };
    };
  };
  
  # Work-specific packages
  environment.systemPackages = with pkgs; [
    # Communication
    slack
    zoom-us
    microsoft-teams
    
    # Development
    vscode
    docker
    docker-compose
    postman
    
    # Office
    libreoffice
    thunderbird
    
    # VPN clients
    openvpn
    networkmanager-openvpn
    
    # Remote access
    remmina
    anydesk
  ];
  
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  
  # Virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };
  
  # Home Manager configuration
  home-manager.users.user = import ./home.nix;
  
  # Work-specific services
  services = {
    # Print server (common in office environments)
    printing = {
      enable = true;
      drivers = with pkgs; [ cups-filters gutenprint ];
    };
    
    # Scanner support
    sane.enable = true;
    
    # Location services for timezone
    geoclue2.enable = true;
  };
  
  # Network shares (if needed for work)
  # fileSystems."/mnt/work-share" = {
  #   device = "//server.work.com/share";
  #   fsType = "cifs";
  #   options = [ "credentials=/etc/nixos/smb-secrets,uid=1000,gid=1000,iocharset=utf8" ];
  # };
  
  # Backup configuration
  services.restic.backups.work = {
    initialize = true;
    repository = "/backup/work-laptop";
    passwordFile = "/etc/nixos/restic-password";
    paths = [
      "/home/user/Documents"
      "/home/user/Projects"
      "/etc/nixos"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
```

# hosts/work-laptop/hardware-configuration.nix

```nix
# This file is generated by nixos-generate-config
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Enable LUKS encryption
  boot.initrd.luks.devices."luks-root" = {
    device = "/dev/disk/by-uuid/12345678-1234-1234-1234-123456789abc";
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  # CPU microcode
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  # Graphics
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  };
  
  # Audio
  hardware.pulseaudio.enable = false;
  
  # Power management
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  
  # Networking
  networking.useDHCP = lib.mkDefault true;
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
```

# hosts/work-laptop/disko.nix

```nix
{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-L" "nixos" "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "16G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
  
  # Enable swap
  swapDevices = [
    { device = "/swap/swapfile"; }
  ];
}
```

# hosts/work-laptop/home.nix

```nix
{ config, lib, pkgs, ... }:
{
  # Desktop applications
  myHome.desktop = {
    enable = true;
    
    browsers = {
      enable = true;
      default = "firefox";
      firefox = {
        enable = true;
        extensions.enable = true;
        bookmarks.enable = true;
        policies.enable = true;
      };
    };
    
    editors = {
      enable = true;
      default = "vscode";
      vscode = {
        enable = true;
        extensions.enable = true;
        userSettings.enable = true;
        keybindings.enable = true;
      };
    };
    
    terminals = {
      enable = true;
      default = "alacritty";
    };
  };
  
  # Development environment
  myHome.development = {
    enable = true;
    
    python = {
      enable = true;
      version = "python311";
      packages.enable = true;
      tools.enable = true;
    };
    
    rust = {
      enable = true;
      channel = "stable";
      cargo.enable = true;
      tools.enable = true;
    };
    
    javascript = {
      enable = true;
      runtime = "nodejs";
      packageManager = "npm";
      typescript.enable = true;
      frameworks.enable = true;
    };
    
    git = {
      enable = true;
      user = {
        name = "Your Name";
        email = "your.email@work.com";
        signingKey = "YOUR_GPG_KEY_ID";
      };
      aliases.enable = true;
      hooks.enable = true;
    };
  };
  
  # Shell configuration
  myHome.shell = {
    enable = true;
    default = "zsh";
    zsh = {
      enable = true;
      ohMyZsh.enable = true;
      plugins.enable = true;
      aliases.enable = true;
    };
  };
  
  # Work-specific home packages
  home.packages = with pkgs; [
    # Communication
    slack
    zoom-us
    
    # Productivity
    obsidian
    notion-app-enhanced
    
    # Development tools
    postman
    dbeaver
    
    # System utilities
    bitwarden
    
    # Media
    vlc
    spotify
  ];
  
  # Work-specific configurations
  programs.git.extraConfig = {
    # Work-specific Git configuration
    url."https://github.com/work-org/".insteadOf = "git@github.com:work-org/";
  };
  
  # SSH configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "work-server" = {
        hostname = "server.work.com";
        user = "username";
        identityFile = "~/.ssh/work_rsa";
      };
    };
  };
  
  # Systemd user services
  systemd.user.services = {
    # Auto-sync work documents
    work-sync = {
      Unit = {
        Description = "Sync work documents";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.rsync}/bin/rsync -av --delete ~/Documents/Work/ backup-server:~/work-backup/";
      };
    };
  };
  
  systemd.user.timers = {
    work-sync = {
      Unit = {
        Description = "Run work-sync every hour";
        Requires = [ "work-sync.service" ];
      };
      Timer = {
        OnCalendar = "hourly";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
```

# hosts/personal-laptop/default.nix

```nix
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];
  
  # System configuration
  mySystem = {
    # Core system
    system = {
      enable = true;
      stateVersion = "24.05";
    };
    
    # Boot configuration
    boot = {
      loader = "systemd-boot";
      secureBoot.enable = true;
    };
    
    # Networking
    networking = {
      enable = true;
      hostName = "personal-laptop";
      wifi.enable = true;
      firewall.enable = true;
    };
    
    # Users
    users = {
      enable = true;
      mainUser = "user";
      users.user = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "audio" "video" "libvirtd" ];
        shell = pkgs.zsh;
      };
    };
    
    # Desktop environment - Hyprland for personal use
    desktop = {
      enable = true;
      environment = "hyprland";
    };
    
    # Hardware
    hardware = {
      enable = true;
      type = "laptop";
    };
    
    # Security
    security = {
      enable = true;
      yubikey = {
        enable = true;
        pam.enable = true;
        gpg.enable = true;
        ssh.enable = true;
        u2f.enable = true;
      };
      hardening = {
        enable = true;
        level = "standard";
      };
    };
  };
  
  # Personal packages
  environment.systemPackages = with pkgs; [
    # Media
    vlc
    mpv
    spotify
    gimp
    inkscape
    blender
    
    # Gaming
    steam
    lutris
    heroic
    
    # Social
    discord
    telegram-desktop
    signal-desktop
    
    # Utilities
    bitwarden
    keepassxc
    
    # Development (personal projects)
    gh
    lazygit
    
    # Creative tools
    audacity
    kdenlive
    obs-studio
  ];
  
  # Gaming support
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  programs.gamemode.enable = true;
  
  # Hardware acceleration for media
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  # Flatpak for some applications
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  
  # Home Manager configuration
  home-manager.users.user = import ./home.nix;
  
  # Personal backup
  services.restic.backups.personal = {
    initialize = true;
    repository = "sftp:backup-server:/backups/personal-laptop";
    passwordFile = "/etc/nixos/restic-password";
    paths = [
      "/home/user/Documents"
      "/home/user/Pictures"
      "/home/user/Projects"
      "/home/user/.config"
    ];
    exclude = [
      "/home/user/.cache"
      "/home/user/.local/share/Steam"
      "*.tmp"
      "node_modules"
      "target"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
```

# hosts/desktop-workstation/default.nix

```nix
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];
  
  # System configuration
  mySystem = {
    # Core system
    system = {
      enable = true;
      stateVersion = "24.05";
    };
    
    # Boot configuration
    boot = {
      loader = "grub";  # GRUB for desktop with multiple drives
      secureBoot.enable = false;  # May not be needed for desktop
    };
    
    # Networking
    networking = {
      enable = true;
      hostName = "desktop-workstation";
      wifi.enable = false;  # Wired connection
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 80 443 8080 3000 ];  # Development ports
      };
    };
    
    # Users
    users = {
      enable = true;
      mainUser = "user";
      users.user = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" "libvirtd" "kvm" ];
        shell = pkgs.zsh;
      };
    };
    
    # Desktop environment - KDE for desktop workstation
    desktop = {
      enable = true;
      environment = "kde";
    };
    
    # Hardware
    hardware = {
      enable = true;
      type = "desktop";
    };
    
    # Security
    security = {
      enable = true;
      yubikey = {
        enable = true;
        pam.enable = true;
        gpg.enable = true;
        ssh.enable = true;
        u2f.enable = true;
        piv.enable = true;
      };
      hardening = {
        enable = true;
        level = "basic";  # Less restrictive for development
      };
    };
    
    # Services
    services = {
      enable = true;
      nginx.enable = true;
      postgresql.enable = true;
      monitoring.enable = true;
    };
  };
  
  # High-performance packages for workstation
  environment.systemPackages = with pkgs; [
    # Development
    vscode
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    docker
    docker-compose
    kubernetes
    kubectl
    minikube
    
    # Design and media
    blender
    gimp
    inkscape
    krita
    kdenlive
    obs-studio
    audacity
    
    # Gaming
    steam
    lutris
    heroic
    
    # Virtualization
    virt-manager
    qemu
    
    # System monitoring
    htop
    btop
    iotop
    
    # Network tools
    wireshark
    nmap
    
    # Productivity
    libreoffice
    thunderbird
    firefox
    chromium
  ];
  
  # Docker with GPU support
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;  # If using NVIDIA GPU
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  
  # KVM/QEMU virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };
  
  # NVIDIA drivers (if applicable)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  # Steam gaming optimizations
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  programs.gamemode.enable = true;
  
  # Home Manager configuration
  home-manager.users.user = import ./home.nix;
  
  # Development services
  services = {
    # PostgreSQL for development
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      ensureDatabases = [ "development" "testing" ];
      ensureUsers = [
        {
          name = "user";
          ensurePermissions = {
            "DATABASE development" = "ALL PRIVILEGES";
            "DATABASE testing" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    
    # Redis for caching
    redis = {
      servers.default = {
        enable = true;
        port = 6379;
      };
    };
    
    # Nginx for local development
    nginx = {
      enable = true;
      virtualHosts = {
        "localhost" = {
          root = "/var/www/html";
          locations."/" = {
            index = "index.html index.php";
          };
        };
      };
    };
  };
  
  # Backup for important data
  services.restic.backups.workstation = {
    initialize = true;
    repository = "sftp:backup-server:/backups/desktop-workstation";
    passwordFile = "/etc/nixos/restic-password";
    paths = [
      "/home/user/Documents"
      "/home/user/Projects"
      "/home/user/Pictures"
      "/var/lib/postgresql"
    ];
    exclude = [
      "/home/user/.cache"
      "/home/user/.local/share/Steam"
      "node_modules"
      "target"
      "*.tmp"
      "*.log"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}