{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.hardening.auditd.enable {
    # Auditd configuration
    services.auditd = {
      enable = true;
      rules = [
        "-w /etc/passwd -p wa -k passwd_changes"
        "-w /etc/shadow -p wa -k shadow_changes"
        "-w /etc/group -p wa -k group_changes"
        "-w /etc/gshadow -p wa -k gshadow_changes"
        "-w /etc/sudoers -p wa -k sudoers_changes"
        "-w /var/log/lastlog -p wa -k logins"
        "-w /var/log/faillog -p wa -k logins"
        "-w /var/log/secure -p wa -k logins"
      ];
      extraConfig = ''
        # Auditd extra configuration
        max_log_file = 8
        num_logs = 5
        space_left_action = SYSLOG
        action_mail_acct = root
      '';
    };
    
    # Install audit tools
    environment.systemPackages = with pkgs; [
      audit
    ];
  };
}
