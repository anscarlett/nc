{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.desktop.browsers.firefox.policies.enable {
    programs.firefox = {
      policies = {
        # Security policies
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = false;
        DisableFirefoxScreenshots = false;
        
        # Privacy policies
        EnableTrackingProtection = {
          Value = true;
          Locked = false;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };
        
        # DNS over HTTPS
        DNSOverHTTPS = {
          Enabled = true;
          ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
          Locked = false;
        };
        
        # Certificate policies
        Certificates = {
          Install = [];  # Add custom certificates here if needed
        };
        
        # Extension policies
        ExtensionSettings = {
          # uBlock Origin - force install
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          
          # Bitwarden - allow install
        };
      };
    };
  };
}
