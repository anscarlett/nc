{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.ssh.enable {
    # SSH configuration for YubiKey
    programs.ssh = {
      startAgent = !config.mySystem.security.yubikey.gpg.enable;
      agentTimeout = "1h";
      
      # Global SSH configuration
      extraConfig = ''
        # YubiKey SSH configuration
        Host *
            IdentitiesOnly yes
            AddKeysToAgent yes
            
        # Use GPG agent for SSH if GPG is enabled
        ${lib.optionalString config.mySystem.security.yubikey.gpg.enable ''
        IdentityAgent ${config.programs.gnupg.agent.socketPath}
        ''}
      '';
    };
    
    # OpenSSH daemon configuration
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        # Security hardening
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
        AuthenticationMethods = "publickey";
        
        # YubiKey specific
        ChallengeResponseAuthentication = true;
        UsePAM = true;
      };
      
      # Additional security options
      extraConfig = ''
        # YubiKey SSH configuration
        AuthorizedKeysCommandUser nobody
        MaxAuthTries 3
        ClientAliveInterval 300
        ClientAliveCountMax 2
      '';
    };
    
    # Install SSH utilities
    environment.systemPackages = with pkgs; [
      openssh
      ssh-import-id
    ];
  };
}
