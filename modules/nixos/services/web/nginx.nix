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
