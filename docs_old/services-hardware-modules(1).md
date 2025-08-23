# modules/nixos/services/default.nix

```nix
{
  imports = [
    ./web
    ./databases
    ./monitoring
    ./backup
  ];
  
  options.mySystem.services = {
    enable = lib.mkEnableOption "system services";
  };
}
```

# modules/nixos/services/web/nginx.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.services.nginx = {
    enable = lib.mkEnableOption "Nginx web server";
    
    user = lib.mkOption {
      type = lib.types.str;
      default = "nginx";
      description = "User to run Nginx as";
    };
    
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Domain name for this virtual host";
          };
          
          root = lib.mkOption {
            type = lib.types.str;
            description = "Document root for this virtual host";
          };
          
          ssl = {
            enable = lib.mkEnableOption "SSL/TLS";
            
            certificatePath = lib.mkOption {
              type = lib.types.str;
              description = "Path to SSL certificate";
            };
            
            keyPath = lib.mkOption {
              type = lib.types.str;
              description = "Path to SSL private key";
            };
          };
          
          locations = lib.mkOption {
            type = lib.types.attrsOf lib.types.attrs;
            default = {};
            description = "Location blocks for this virtual host";
          };
        };
      });
      default = {};
      description = "Virtual hosts configuration";
    };
    
    upstreams = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          servers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Upstream servers";
          };
          
          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Additional upstream configuration";
          };
        };
      });
      default = {};
      description = "Upstream server groups";
    };
    
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Nginx configuration";
    };
  };
  
  config = lib.mkIf config.mySystem.services.nginx.enable {
    services.nginx = {
      enable = true;
      user = config.mySystem.services.nginx.user;
      
      # Security-focused configuration
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      
      # Virtual hosts
      virtualHosts = lib.mapAttrs (name: vhost: {
        serverName = vhost.domain;
        root = vhost.root;
        
        # SSL configuration
        enableACME = vhost.ssl.enable;
        forceSSL = vhost.ssl.enable;
        sslCertificate = lib.mkIf vhost.ssl.enable vhost.ssl.certificatePath;
        sslCertificateKey = lib.mkIf vhost.ssl.enable vhost.ssl.keyPath;
        
        # Location blocks
        locations = vhost.locations;
      }) config.mySystem.services.nginx.virtualHosts;
      
      # Upstream configuration
      upstreams = lib.mapAttrs (name: upstream: {
        servers = lib.genAttrs upstream.servers (server: {});
        extraConfig = upstream.extraConfig;
      }) config.mySystem.services.nginx.upstreams;
      
      # Additional configuration
      appendHttpConfig = ''
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Content-Security-Policy "default-src 'self'" always;
        
        # Rate limiting
        limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
        limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
        
        # Log format
        log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for"';
        
        ${config.mySystem.services.nginx.extraConfig}
      '';
    };
    
    # Firewall configuration
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    
    # ACME configuration for SSL certificates
    security.acme = lib.mkIf (lib.any (vhost: vhost.ssl.enable) (lib.attrValues config.mySystem.services.nginx.virtualHosts)) {
      acceptTerms = true;
      defaults.email = "admin@example.com";  # Override per-host
    };
    
    # Nginx monitoring
    services.prometheus.exporters.nginx = lib.mkIf config.mySystem.services.monitoring.enable {
      enable = true;
      port = 9113;
    };
  };
}
```

# modules/nixos/services/databases/postgresql.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.services.postgresql = {
    enable = lib.mkEnableOption "PostgreSQL database server";
    
    version = lib.mkOption {
      type = lib.types.str;
      default = "15";
      description = "PostgreSQL version to use";
    };
    
    port = lib.mkOption {
      type = lib.types.port;
      default = 5432;
      description = "Port for PostgreSQL to listen on";
    };
    
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/postgresql/${config.mySystem.services.postgresql.version}";
      description = "Data directory for PostgreSQL";
    };
    
    authentication = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        local   all             all                                     trust
        host    all             all             127.0.0.1/32            trust
        host    all             all             ::1/128                 trust
      '';
      description = "PostgreSQL authentication configuration";
    };
    
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "PostgreSQL configuration settings";
    };
    
    databases = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Database name";
          };
          
          owner = lib.mkOption {
            type = lib.types.str;
            default = "postgres";
            description = "Database owner";
          };
          
          encoding = lib.mkOption {
            type = lib.types.str;
            default = "UTF8";
            description = "Database encoding";
          };
        };
      });
      default = [];
      description = "Databases to create";
    };
    
    users = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Username";
          };
          
          createDatabase = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Create a database with the same name as the user";
          };
          
          superuser = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Grant superuser privileges";
          };
          
          passwordFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Path to file containing the user's password";
          };
        };
      });
      default = [];
      description = "Users to create";
    };
    
    backup = {
      enable = lib.mkEnableOption "PostgreSQL backups";
      
      schedule = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        description = "Backup schedule";
      };
      
      location = lib.mkOption {
        type = lib.types.str;
        default = "/var/backup/postgresql";
        description = "Backup location";
      };
      
      compression = lib.mkOption {
        type = lib.types.enum [ "none" "gzip" "zstd" ];
        default = "gzip";
        description = "Backup compression method";
      };
    };
  };
  
  config = lib.mkIf config.mySystem.services.postgresql.enable {
    services.postgresql = {
      enable = true;
      package = pkgs."postgresql_${config.mySystem.services.postgresql.version}";
      port = config.mySystem.services.postgresql.port;
      dataDir = config.mySystem.services.postgresql.dataDir;
      
      # Authentication
      authentication = config.mySystem.services.postgresql.authentication;
      
      # Configuration settings
      settings = {
        # Connection settings
        listen_addresses = "'localhost'";
        max_connections = 100;
        
        # Memory settings
        shared_buffers = "256MB";
        effective_cache_size = "1GB";
        maintenance_work_mem = "64MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        
        # Logging
        log_destination = "'stderr'";
        logging_collector = true;
        log_directory = "'pg_log'";
        log_filename = "'postgresql-%Y-%m-%d_%H%M%S.log'";
        log_statement = "'mod'";
        log_min_duration_statement = 1000;
        
        # Security
        ssl = true;
        ssl_ciphers = "'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384'";
        ssl_prefer_server_ciphers = true;
        
        # Performance
        synchronous_commit = true;
        checkpoint_segments = 32;
        checkpoint_completion_target = 0.7;
        wal_level = "'replica'";
        max_wal_senders = 3;
        wal_keep_segments = 8;
      } // config.mySystem.services.postgresql.settings;
      
      # Create databases
      ensureDatabases = map (db: db.name) config.mySystem.services.postgresql.databases;
      
      # Create users
      ensureUsers = map (user: {
        name = user.name;
        ensurePermissions = lib.mkIf user.createDatabase {
          "DATABASE ${user.name}" = "ALL PRIVILEGES";
        };
      }) config.mySystem.services.postgresql.users;
    };
    
    # Backup configuration
    services.postgresqlBackup = lib.mkIf config.mySystem.services.postgresql.backup.enable {
      enable = true;
      databases = map (db: db.name) config.mySystem.services.postgresql.databases;
      startAt = config.mySystem.services.postgresql.backup.schedule;
      location = config.mySystem.services.postgresql.backup.location;
      compression = config.mySystem.services.postgresql.backup.compression;
    };
    
    # Monitoring
    services.prometheus.exporters.postgres = lib.mkIf config.mySystem.services.monitoring.enable {
      enable = true;
      port = 9187;
      dataSourceName = "postgresql://prometheus@localhost:${toString config.mySystem.services.postgresql.port}/postgres?sslmode=disable";
    };
    
    # Firewall (only allow local connections by default)
    # networking.firewall.allowedTCPPorts = [ config.mySystem.services.postgresql.port ];
  };
}
```

# modules/nixos/services/monitoring/prometheus.nix

```nix
{ config, lib, pkgs, ... }:
{
  options.mySystem.services.prometheus = {
    enable = lib.mkEnableOption "Prometheus monitoring";
    
    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Port for Prometheus to listen on";
    };
    
    retention = lib.mkOption {
      type = lib.types.str;
      default = "30d";
      description = "Data retention period";
    };
    
    scrapeConfigs = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Prometheus scrape configurations";
    };
    
    alertmanager = {
      enable = lib.mkEnableOption "Alertmanager";
      
      port = lib.mkOption {
        type = lib.types.port;
        default = 9093;
        description = "Port for Alertmanager to listen on";
      };
      
      configuration = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Alertmanager configuration";
      };
    };
    
    grafana = {
      enable = lib.mkEnableOption "Grafana";
      
      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Port for Grafana to listen on";
      };
      
      domain = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Grafana domain name";
      };
      
      adminPassword = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Grafana admin password";
      };
    };
  };
  
  config = lib.mkIf config.mySystem.services.prometheus.enable {
    services.prometheus = {
      enable = true;
      port = config.mySystem.services.prometheus.port;
      retentionTime = config.mySystem.services.prometheus.retention;
      
      exporters = {
        node = {
          enable = true;
          port = 9100;
          enabledCollectors = [
            "systemd"
            "textfile"
            "processes"
          ];
        };
      };
      
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{
            targets = [ "localhost:9100" ];
          }];
        }
        {
          job_name = "prometheus";
          static_configs = [{
            targets = [ "localhost:${toString config.mySystem.services.prometheus.port}" ];
          }];
        }
      ] ++ config.mySystem.services.prometheus.scrapeConfigs;
    };
    
    # Alertmanager
    services.prometheus.alertmanager = lib.mkIf config.mySystem.services.prometheus.alertmanager.enable {
      enable = true;
      port = config.mySystem.services.prometheus.alertmanager.port;
      configuration = {
        global = {
          smtp_smarthost = "localhost:587";
          smtp_from = "alertmanager@localhost";
        };
        
        route = {
          group_by = [ "alertname" ];
          group_wait = "10s";
          group_interval = "10s";
          repeat_interval = "1h";
          receiver = "web.hook";
        };
        
        receivers = [
          {
            name = "web.hook";
            webhook_configs = [
              {
                url = "http://127.0.0.1:5001/";
              }
            ];
          }
        ];
      } // config.mySystem.services.prometheus.alertmanager.configuration;
    };
    
    # Grafana
    services.grafana = lib.mkIf config.mySystem.services.prometheus.grafana.enable {
      enable = true;
      settings = {
        server = {
          http_port = config.mySystem.services.prometheus.grafana.port;
          domain = config.mySystem.services.prometheus.grafana.domain;
        };
        
        security = {
          admin_password = config.mySystem.services.prometheus.grafana.adminPassword;
          secret_key = "changeme";  # Should be overridden per-host
        };
        
        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
        };
        
        users = {
          allow_sign_up = false;
          auto_assign_org = true;
          auto_assign_org_role = "Viewer";
        };
      };
      
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:${toString config.mySystem.services.prometheus.port}";
            isDefault = true;
          }
        ];
      };
    };
    
    # Firewall configuration
    networking.firewall.allowedTCPPorts = [
      config.mySystem.services.prometheus.port
    ] ++ lib.optionals config.mySystem.services.prometheus.alertmanager.enable [
      config.mySystem.services.prometheus.alertmanager.port
    ] ++ lib.optionals config.mySystem.services.prometheus.grafana.enable [
      config.mySystem.services.prometheus.grafana.port
    ];
  };
}
```

# modules/nixos/hardware/default.nix

```nix
{
  imports = [
    ./laptop
    ./desktop
    ./server
  ];
  
  options.mySystem.hardware = {
    enable = lib.mkEnableOption "hardware configuration";
    
    type = lib.mkOption {
      type = lib.types.enum [ "laptop" "desktop" "server" ];
      description = "Hardware type";
    };
  };
  
  config = lib.mkIf config.mySystem.hardware.enable {
    # Auto-enable hardware modules based on type
    mySystem.hardware.laptop.enable = lib.mkIf (config.mySystem.hardware.type == "laptop") true;
    mySystem.hardware.desktop.enable = lib.mkIf (config.mySystem.hardware.type == "desktop") true;
    mySystem.hardware.server.enable = lib.mkIf (config.mySystem.hardware.type == "server") true;
  };
}
```

# modules/nixos/hardware/laptop/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./power-management.nix
    ./display.nix
    ./input.nix
  ];
  
  options.mySystem.hardware.laptop = {
    enable = lib.mkEnableOption "laptop hardware configuration";
    
    powerManagement.enable = lib.mkEnableOption "laptop power management" // { default = true; };
    display.enable = lib.mkEnableOption "laptop display configuration" // { default = true; };
    input.enable = lib.mkEnableOption "laptop input configuration" // { default = true; };
    
    wifi.enable = lib.mkEnableOption "WiFi support" // { default = true; };
    bluetooth.enable = lib.mkEnableOption "Bluetooth support" // { default = true; };
    
    manufacturer = lib.mkOption {
      type = lib.types.enum [ "generic" "thinkpad" "dell" "hp" "framework" "apple" ];
      default = "generic";
      description = "Laptop manufacturer for specific optimizations";
    };
  };
  
  config = lib.mkIf config.mySystem.hardware.laptop.enable {
    # Enable WiFi
    networking.wireless.enable = lib.mkIf config.mySystem.hardware.laptop.wifi.enable true;
    
    # Bluetooth
    hardware.bluetooth = lib.mkIf config.mySystem.hardware.laptop.bluetooth.enable {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
    
    services.blueman.enable = lib.mkIf config.mySystem.hardware.laptop.bluetooth.enable true;
    
    # Audio
    sound.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Graphics
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    
    # Firmware
    hardware.enableRedistributableFirmware = true;
    
    # USB automounting
    services.udisks2.enable = true;
    
    # Manufacturer-specific configurations
    hardware.trackpoint.enable = lib.mkIf (config.mySystem.hardware.laptop.manufacturer == "thinkpad") true;
    
    # Framework laptop specific
    hardware.framework.enable = lib.mkIf (config.mySystem.hardware.laptop.manufacturer == "framework") true;
    
    # Apple hardware
    hardware.facetimehd.enable = lib.mkIf (config.mySystem.hardware.laptop.manufacturer == "apple") true;
    
    # Laptop mode tools
    services.laptop-mode = {
      enable = true;
      powerSupply = "/sys/class/power_supply/ADP1";
      writeCacheTimeout = 60;
    };
    
    # TLP for better battery life
    services.tlp = {
      enable = true;
      settings = {
        # CPU settings
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 80;
        
        # Radio device settings
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
        WOL_DISABLE = "Y";
        
        # Battery care
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
        
        # USB settings
        USB_AUTOSUSPEND = 1;
        USB_BLACKLIST_PHONE = 1;
        
        # SATA settings
        SATA_LINKPWR_ON_AC = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "min_power";
      };
    };
  };
}
```

# modules/nixos/hardware/laptop/power-management.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.hardware.laptop.powerManagement.enable {
    # CPU frequency scaling
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "ondemand";
      powertop.enable = true;
    };
    
    # Suspend and hibernation
    systemd.sleep.extraConfig = ''
      HibernateDelaySec=3600
      SuspendMode=suspend
      HibernateMode=platform shutdown
    '';
    
    # Power profiles daemon
    services.power-profiles-daemon.enable = true;
    
    # Thermald for Intel CPUs
    services.thermald.enable = lib.mkDefault true;
    
    # Auto-cpufreq as alternative to TLP
    # services.auto-cpufreq = {
    #   enable = true;
    #   settings = {
    #     battery = {
    #       governor = "powersave";
    #       turbo = "never";
    #     };
    #     charger = {
    #       governor = "performance";
    #       turbo = "auto";
    #     };
    #   };
    # };
    
    # ACPI event handling
    services.acpid = {
      enable = true;
      lidEventCommands = ''
        # Suspend on lid close
        LID_STATE=/proc/acpi/button/lid/LID/state
        if [ -f $LID_STATE ]; then
          if grep -q closed $LID_STATE; then
            systemctl suspend
          fi
        fi
      '';
      
      powerEventCommands = ''
        # Handle power button
        systemctl suspend
      '';
    };
    
    # Battery monitoring
    services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "Hibernate";
    };
    
    # Tools for power management
    environment.systemPackages = with pkgs; [
      powertop
      acpi
      lm_sensors
      stress
      s-tui
      turbostat
      intel-gpu-tools
    ];
  };
}
```

# modules/nixos/hardware/laptop/display.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.hardware.laptop.display.enable {
    # X11 display configuration
    services.xserver = {
      enable = lib.mkDefault true;
      
      # DPI settings for high-DPI displays
      dpi = lib.mkDefault 96;
      
      # Input class sections
      inputClassSections = [
        # Touchpad configuration
        ''
          Identifier "touchpad catchall"
          Driver "libinput"
          MatchIsTouchpad "on"
          MatchDevicePath "/dev/input/event*"
          Option "Tapping" "on"
          Option "TappingButtonMap" "lrm"
          Option "NaturalScrolling" "true"
          Option "ScrollMethod" "twofinger"
          Option "DisableWhileTyping" "true"
          Option "AccelProfile" "adaptive"
        ''
      ];
    };
    
    # Backlight control
    programs.light.enable = true;
    services.actkbd = {
      enable = true;
      bindings = [
        { keys = [ 224 ]; events = [ "key" ]; command = "${pkgs.light}/bin/light -U 5"; }
        { keys = [ 225 ]; events = [ "key" ]; command = "${pkgs.light}/bin/light -A 5"; }
      ];
    };
    
    # Color temperature adjustment
    services.redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.8";
      };
      temperature = {
        day = 6500;
        night = 4500;
      };
    };
    
    # Screen rotation for convertible laptops
    hardware.sensor.iio.enable = true;
    
    # Display tools
    environment.systemPackages = with pkgs; [
      brightnessctl
      ddcutil
      autorandr
      arandr
      xorg.xrandr
      wlr-randr  # For Wayland
    ];
    
    # Automatic display configuration
    services.autorandr.enable = true;
    
    # HiDPI support
    console.font = lib.mkIf (config.services.xserver.dpi > 120) "${pkgs.terminus_font}/share/consolefonts/ter-v24n.psf.gz";
    
    # Font scaling for HiDPI
    fonts.fontconfig.defaultFonts = lib.mkIf (config.services.xserver.dpi > 120) {
      serif = [ "DejaVu Serif" ];
      sansSerif = [ "DejaVu Sans" ];
      monospace = [ "DejaVu Sans Mono" ];
    };
  };
}
```

# modules/nixos/hardware/laptop/input.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.hardware.laptop.input.enable {
    # Libinput configuration
    services.xserver.libinput = {
      enable = true;
      
      # Touchpad settings
      touchpad = {
        tapping = true;
        naturalScrolling = true;
        disableWhileTyping = true;
        middleEmulation = true;
        accelProfile = "adaptive";
        clickMethod = "clickfinger";
      };
      
      # Mouse settings
      mouse = {
        accelProfile = "adaptive";
        naturalScrolling = false;
      };
    };
    
    # Keyboard configuration
    services.xserver.xkb = {
      layout = "us";
      options = "caps:escape";  # Map Caps Lock to Escape
    };
    
    # Input method support
    i18n.inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        uniemoji
      ];
    };
    
    # Gaming input support
    hardware.steam-hardware.enable = lib.mkDefault false;
    
    # Input tools
    environment.systemPackages = with pkgs; [
      libinput
      xinput
      xorg.xev
      evtest
      input-utils
    ];
    
    # Gesture support
    services.touchegg.enable = true;
    
    # Special keys handling
    services.actkbd = {
      enable = true;
      bindings = [
        # Volume controls
        { keys = [ 113 ]; events = [ "key" ]; command = "${pkgs.alsa-utils}/bin/amixer -q set Master toggle"; }
        { keys = [ 114 ]; events = [ "key" ]; command = "${pkgs.alsa-utils}/bin/amixer -q set Master 5%- unmute"; }
        { keys = [ 115 ]; events = [ "key" ]; command = "${pkgs.alsa-utils}/bin/amixer -q set Master 5%+ unmute"; }
        
        # Brightness controls (handled in display.nix)
        
        # Media controls
        { keys = [ 163 ]; events = [ "key" ]; command = "${pkgs.playerctl}/bin/playerctl next"; }
        { keys = [ 165 ]; events = [ "key" ]; command = "${pkgs.playerctl}/bin/playerctl previous"; }
        { keys = [ 164 ]; events = [ "key" ]; command = "${pkgs.playerctl}/bin/playerctl play-pause"; }
      ];
    };
  };
}