{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.hardening.enable {
    # System hardening options
    security.apparmor.enable = true;
    security.audit.enable = true;
    security.lockKernelModules = true;
    security.protectKernelImage = true;
    security.sudo.extraConfig = ''
      Defaults use_pty
      Defaults log_input,log_output
    '';
    
    # Kernel hardening
    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.yama.ptrace_scope" = 1;
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
      "fs.protected_fifos" = 1;
      "fs.protected_regular" = 1;
    };
    
    # Disable unused filesystems
    boot.blacklistedKernelModules = [
      "cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "squashfs" "udf" "vfat"
    ];
    
    # Remove setuid/setgid bits from world-writable files
    systemd.tmpfiles.rules = [
      "z /tmp 1777 root root 1d"
      "z /var/tmp 1777 root root 1d"
    ];
    
    # Install hardening tools
    environment.systemPackages = with pkgs; [
      lynis
      chkrootkit
      rkhunter
    ];
  };
}
