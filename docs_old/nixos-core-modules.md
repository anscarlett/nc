# modules/nixos/default.nix

```nix
{
  imports = [
    ./core
    ./desktop  
    ./security
    ./services
    ./hardware
  ];
}
```

# modules/nixos/core/default.nix

```nix
{
  imports = [
    ./boot
    ./networking
    ./users
    ./system
  ];
}
```

# modules/nixos/core/boot/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./systemd-boot.nix
    ./grub.nix  
    ./secure-boot.nix
  ];
  
  options.mySystem.boot = {
    loader = lib.mkOption {
      type = lib.types.enum [ "systemd-boot" "grub" ];
      default = "systemd-boot";
      description = "Boot loader to use";
    };
    
    secureBoot.enable = lib.mkEnableOption "Secure Boot with YubiKey";
    
    kernel = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.linuxPackages_latest.kernel;
        description = "Kernel package to use";
      };
      
      parameters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional kernel parameters";
      };
    };
  };
  
  config = {
    # Common boot settings that apply to all loaders
    boot = {
      kernelPackages = lib.mkDefault (lib.mkIf (config.mySystem.boot.kernel.package != null) 
        (pkgs.linuxPackagesFor config.mySystem.boot.kernel.package));
      
      kernelParams = config.mySystem.boot.kernel.parameters;
      
      # Enable Plymouth for better boot experience
      plymouth.enable = lib.mkDefault true;
      
      # Optimize boot time
      initrd.systemd.enable = lib.mkDefault true;
    };
  };
}
```

# modules/nixos/core/boot/systemd-boot.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.mySystem.boot.loader == "systemd-boot") {
    boot.loader = {
      systemd-boot = {
        enable = true;
        editor = false;
        configurationLimit = 10;
        memtest86.enable = true;
      };
      
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };
}
```

# modules/nixos/core/boot/grub.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf (config.mySystem.boot.loader == "grub") {
    boot.loader = {
      grub = {
        enable = true;
        version = 2;
        efiSupport = true;
        enableCryptodisk = true;
        configurationLimit = 10;
        theme = pkgs.nixos-grub2-theme;
      };
      
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };
}
```

# modules/nixos/core/boot/secure-boot.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.boot.secureBoot.enable {
    # Secure Boot configuration with YubiKey
    boot = {
      loader.systemd-boot.enable = lib.mkForce false;
      
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };
    };
    
    # YubiKey integration for secure boot
    environment.systemPackages = with pkgs; [
      sbctl
      efibootmgr
    ];
  };
}
```

# modules/nixos/core/networking/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./wifi.nix
    ./vpn.nix
    ./firewall.nix
  ];
  
  options.mySystem.networking = {
    enable = lib.mkEnableOption "networking configuration" // {
      default = true;
    };
    
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "System hostname";
    };
    
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "System domain name";
    };
    
    enableIPv6 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable IPv6 support";
    };
    
    wifi.enable = lib.mkEnableOption "WiFi support";
    vpn.enable = lib.mkEnableOption "VPN clients";
    firewall.enable = lib.mkEnableOption "firewall" // { default = true; };
  };
  
  config = lib.mkIf config.mySystem.networking.enable {
    networking = {
      hostName = config.mySystem.networking.hostName;
      domain = config.mySystem.networking.domain;
      
      # Enable networkd for systemd-based networking
      useNetworkd = lib.mkDefault true;
      useDHCP = lib.mkDefault false;
      
      # IPv6 configuration
      enableIPv6 = config.mySystem.networking.enableIPv6;
      
      # DNS configuration
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
      
      # Network interfaces
      interfaces = {
        # This will be configured per-host
      };
    };
    
    # Enable systemd-resolved for DNS resolution
    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = lib.mkIf (config.mySystem.networking.domain != null) [ config.mySystem.networking.domain ];
      fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}
```

# modules/nixos/core/networking/wifi.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.networking.wifi.enable {
    networking.wireless = {
      enable = true;
      userControlled.enable = true;
      
      # Use wpa_supplicant for enterprise networks
      environmentFile = "/etc/wpa_supplicant.env";
    };
    
    # Alternative: NetworkManager for easier WiFi management
    # networking.networkmanager = {
    #   enable = true;
    #   wifi.powersave = false;
    # };
    
    # Install WiFi management tools
    environment.systemPackages = with pkgs; [
      wpa_supplicant_gui
      wavemon
      iw
    ];
  };
}
```

# modules/nixos/core/networking/vpn.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.networking.vpn.enable {
    # OpenVPN client support
    services.openvpn.servers = {
      # Configuration will be per-host specific
    };
    
    # WireGuard support
    networking.wireguard.enable = true;
    
    # VPN client packages
    environment.systemPackages = with pkgs; [
      openvpn
      wireguard-tools
      networkmanager-openvpn
      networkmanager-vpnc
    ];
  };
}
```

# modules/nixos/core/networking/firewall.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.networking.firewall = {
    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = "Additional TCP ports to allow";
    };
    
    allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [];
      description = "Additional UDP ports to allow";
    };
    
    trustedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Network interfaces to trust completely";
    };
  };
  
  config = lib.mkIf config.mySystem.networking.firewall.enable {
    networking.firewall = {
      enable = true;
      
      # Default allowed ports
      allowedTCPPorts = [ 22 ] ++ config.mySystem.networking.firewall.allowedTCPPorts;
      allowedUDPPorts = config.mySystem.networking.firewall.allowedUDPPorts;
      
      # Trusted interfaces (like VPN)
      trustedInterfaces = config.mySystem.networking.firewall.trustedInterfaces;
      
      # Ping responses
      allowPing = true;
      
      # Log refused connections
      logRefusedConnections = false;
    };
  };
}
```

# modules/nixos/core/users/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./sudo.nix
    ./groups.nix
  ];
  
  options.mySystem.users = {
    enable = lib.mkEnableOption "user management" // { default = true; };
    
    mainUser = lib.mkOption {
      type = lib.types.str;
      description = "Primary user account name";
    };
    
    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          isNormalUser = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether this is a normal user account";
          };
          
          extraGroups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional groups for this user";
          };
          
          shell = lib.mkOption {
            type = lib.types.package;
            default = pkgs.zsh;
            description = "Default shell for this user";
          };
          
          openssh.authorizedKeys.keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "SSH authorized keys for this user";
          };
        };
      });
      default = {};
      description = "User accounts to create";
    };
  };
  
  config = lib.mkIf config.mySystem.users.enable {
    users.users = lib.mapAttrs (name: userConfig: {
      isNormalUser = userConfig.isNormalUser;
      extraGroups = [ "wheel" "networkmanager" ] ++ userConfig.extraGroups;
      shell = userConfig.shell;
      openssh.authorizedKeys.keys = userConfig.openssh.authorizedKeys.keys;
    }) config.mySystem.users.users;
    
    # Enable zsh system-wide if any user uses it
    programs.zsh.enable = lib.mkIf (lib.any (user: user.shell == pkgs.zsh) (lib.attrValues config.mySystem.users.users)) true;
    
    # Set default shell programs
    environment.shells = with pkgs; [ bash zsh fish ];
  };
}
```

# modules/nixos/core/users/sudo.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.users.sudo = {
    enable = lib.mkEnableOption "sudo configuration" // { default = true; };
    
    wheelNeedsPassword = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether wheel group users need password for sudo";
    };
    
    extraRules = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Additional sudo rules";
    };
  };
  
  config = lib.mkIf config.mySystem.users.sudo.enable {
    security.sudo = {
      enable = true;
      wheelNeedsPassword = config.mySystem.users.sudo.wheelNeedsPassword;
      extraRules = config.mySystem.users.sudo.extraRules;
    };
  };
}
```

# modules/nixos/core/users/groups.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.users.groups = {
    development = lib.mkEnableOption "development groups (docker, libvirtd)";
    media = lib.mkEnableOption "media groups (audio, video)";
    hardware = lib.mkEnableOption "hardware groups (input, lp)";
  };
  
  config = {
    users.groups = lib.mkMerge [
      (lib.mkIf config.mySystem.users.groups.development {
        docker = {};
        libvirtd = {};
      })
      
      (lib.mkIf config.mySystem.users.groups.media {
        audio = {};
        video = {};
      })
      
      (lib.mkIf config.mySystem.users.groups.hardware {
        input = {};
        lp = {};
        scanner = {};
      })
    ];
  };
}
```

# modules/nixos/core/system/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./locale.nix
    ./fonts.nix
    ./nix.nix
  ];
  
  options.mySystem.system = {
    enable = lib.mkEnableOption "base system configuration" // { default = true; };
    
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "NixOS state version";
    };
    
    autoUpgrade = {
      enable = lib.mkEnableOption "automatic system upgrades";
      
      allowReboot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow automatic reboots for kernel updates";
      };
      
      channel = lib.mkOption {
        type = lib.types.str;
        default = "nixos-unstable";
        description = "NixOS channel to use for upgrades";
      };
    };
  };
  
  config = lib.mkIf config.mySystem.system.enable {
    system.stateVersion = config.mySystem.system.stateVersion;
    
    # Automatic upgrades
    system.autoUpgrade = lib.mkIf config.mySystem.system.autoUpgrade.enable {
      enable = true;
      allowReboot = config.mySystem.system.autoUpgrade.allowReboot;
      channel = config.mySystem.system.autoUpgrade.channel;
      dates = "weekly";
    };
    
    # Enable documentation
    documentation = {
      enable = true;
      nixos.enable = true;
      man.enable = true;
      info.enable = true;
    };
    
    # Basic system packages
    environment.systemPackages = with pkgs; [
      # System utilities
      curl
      wget
      git
      vim
      nano
      htop
      tree
      unzip
      zip
      rsync
      
      # Network utilities
      dig
      nmap
      tcpdump
      
      # File system utilities
      file
      lsof
      pciutils
      usbutils
    ];
  };
}
```

# modules/nixos/core/system/locale.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.system.locale = {
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Default system locale";
    };
    
    extraLocales = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional locales to generate";
    };
    
    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "System timezone";
    };
    
    keyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Console keymap";
    };
  };
  
  config = {
    # Locale configuration
    i18n.defaultLocale = config.mySystem.system.locale.defaultLocale;
    i18n.extraLocaleSettings = lib.mkIf (config.mySystem.system.locale.extraLocales != []) 
      (lib.genAttrs config.mySystem.system.locale.extraLocales (locale: locale));
    
    # Timezone
    time.timeZone = config.mySystem.system.locale.timeZone;
    
    # Console configuration
    console = {
      keyMap = config.mySystem.system.locale.keyMap;
      font = "Lat2-Terminus16";
    };
  };
}
```

# modules/nixos/core/system/fonts.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.system.fonts = {
    enable = lib.mkEnableOption "font configuration" // { default = true; };
    
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        # System fonts
        dejavu_fonts
        liberation_ttf
        
        # Programming fonts
        (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
        
        # Additional fonts
        ubuntu_font_family
        google-fonts
      ];
      description = "Font packages to install";
    };
    
    fontconfig = {
      enable = lib.mkEnableOption "fontconfig" // { default = true; };
      
      defaultFonts = {
        serif = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "DejaVu Serif" ];
          description = "Default serif fonts";
        };
        
        sansSerif = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "DejaVu Sans" ];
          description = "Default sans-serif fonts";
        };
        
        monospace = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "FiraCode Nerd Font Mono" "DejaVu Sans Mono" ];
          description = "Default monospace fonts";
        };
      };
    };
  };
  
  config = lib.mkIf config.mySystem.system.fonts.enable {
    fonts = {
      packages = config.mySystem.system.fonts.packages;
      
      fontconfig = lib.mkIf config.mySystem.system.fonts.fontconfig.enable {
        enable = true;
        
        defaultFonts = {
          serif = config.mySystem.system.fonts.fontconfig.defaultFonts.serif;
          sansSerif = config.mySystem.system.fonts.fontconfig.defaultFonts.sansSerif;
          monospace = config.mySystem.system.fonts.fontconfig.defaultFonts.monospace;
        };
        
        # Enable font antialiasing
        antialias = true;
        hinting.enable = true;
        subpixel.rgba = "rgb";
      };
    };
  };
}
```

# modules/nixos/core/system/nix.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.system.nix = {
    enable = lib.mkEnableOption "Nix daemon configuration" // { default = true; };
    
    flakes = lib.mkEnableOption "experimental flakes support" // { default = true; };
    
    autoOptimiseStore = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically optimize the Nix store";
    };
    
    gc = {
      automatic = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic garbage collection";
      };
      
      dates = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "When to run garbage collection";
      };
      
      options = lib.mkOption {
        type = lib.types.str;
        default = "--delete-older-than 30d";
        description = "Garbage collection options";
      };
    };
    
    extraOptions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Nix configuration";
    };
  };
  
  config = lib.mkIf config.mySystem.system.nix.enable {
    nix = {
      package = pkgs.nixFlakes;
      
      settings = {
        # Enable flakes and new command
        experimental-features = lib.mkIf config.mySystem.system.nix.flakes [ "nix-command" "flakes" ];
        
        # Optimize store automatically
        auto-optimise-store = config.mySystem.system.nix.autoOptimiseStore;
        
        # Build settings
        max-jobs = "auto";
        cores = 0;
        
        # Trusted users for multi-user builds
        trusted-users = [ "root" "@wheel" ];
        
        # Binary caches
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      
      # Garbage collection
      gc = lib.mkIf config.mySystem.system.nix.gc.automatic {
        automatic = true;
        dates = config.mySystem.system.nix.gc.dates;
        options = config.mySystem.system.nix.gc.options;
      };
      
      # Extra configuration
      extraOptions = config.mySystem.system.nix.extraOptions;
    };
    
    # Enable nh for better Nix commands
    environment.systemPackages = with pkgs; [
      nh
      nix-output-monitor
      nvd
    ];
  };
}
```