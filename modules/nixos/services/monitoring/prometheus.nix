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
