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
        ###checkpoint_completion_target = 0.9;
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
