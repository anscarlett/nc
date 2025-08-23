# modules/nixos/security/default.nix

```nix
{
  imports = [
    ./yubikey
    ./hardening
    ./certificates
  ];
  
  options.mySystem.security = {
    enable = lib.mkEnableOption "security configuration" // { default = true; };
  };
}
```

# modules/nixos/security/yubikey/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./pam.nix
    ./gpg.nix
    ./ssh.nix
    ./luks.nix
    ./u2f.nix
    ./piv.nix
  ];
  
  options.mySystem.security.yubikey = {
    enable = lib.mkEnableOption "YubiKey support";
    
    pam.enable = lib.mkEnableOption "YubiKey PAM authentication";
    gpg.enable = lib.mkEnableOption "YubiKey GPG support";
    ssh.enable = lib.mkEnableOption "YubiKey SSH support";
    luks.enable = lib.mkEnableOption "YubiKey LUKS support";
    u2f.enable = lib.mkEnableOption "YubiKey U2F support";
    piv.enable = lib.mkEnableOption "YubiKey PIV support";
  };
  
  config = lib.mkIf config.mySystem.security.yubikey.enable {
    # Common YubiKey setup
    services.udev.packages = with pkgs; [ 
      yubikey-personalization 
      yubico-piv-tool
    ];
    
    # YubiKey management tools
    environment.systemPackages = with pkgs; [ 
      yubico-piv-tool 
      yubikey-manager 
      yubikey-manager-qt
      yubikey-personalization
      yubikey-personalization-gui
      yubioath-flutter
    ];
    
    # Enable smartcard daemon
    services.pcscd.enable = true;
    
    # udev rules for YubiKey
    services.udev.extraRules = ''
      # YubiKey 4/5 U2F+CCID
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="uaccess", GROUP="plugdev", MODE="0664"
      
      # YubiKey 4/5 OTP+U2F+CCID
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0405", TAG+="uaccess", GROUP="plugdev", MODE="0664"
      
      # YubiKey 4/5 U2F
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0402", TAG+="uaccess", GROUP="plugdev", MODE="0664"
      
      # YubiKey 4/5 OTP+U2F
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0404", TAG+="uaccess", GROUP="plugdev", MODE="0664"
    '';
  };
}
```

# modules/nixos/security/yubikey/pam.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.pam.enable {
    # YubiKey PAM authentication
    security.pam = {
      # Enable U2F authentication
      u2f = {
        enable = true;
        settings = {
          cue = true;
          interactive = true;
        };
      };
      
      # Configure services for YubiKey authentication
      services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
        polkit-1.u2fAuth = true;
        gdm.u2fAuth = true;
        lightdm.u2fAuth = true;
      };
    };
    
    # YubiKey Challenge-Response for offline authentication
    security.pam.yubico = {
      enable = true;
      debug = false;
      mode = "challenge-response";
      
      # Optional: Use YubiCloud for online validation
      # id = "your-yubikey-id";
      # key = "your-api-key";
    };
    
    # Install pamu2fcfg for U2F key registration
    environment.systemPackages = with pkgs; [
      pam_u2f
      pamu2fcfg
    ];
  };
}
```

# modules/nixos/security/yubikey/gpg.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.gpg.enable {
    # GPG configuration for YubiKey
    programs.gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = config.mySystem.security.yubikey.ssh.enable;
        pinentryPackage = pkgs.pinentry-gtk2;
        settings = {
          default-cache-ttl = 60;
          max-cache-ttl = 120;
          pinentry-timeout = 10;
        };
      };
    };
    
    # Enable smartcard support
    services.pcscd.enable = true;
    
    # GPG tools
    environment.systemPackages = with pkgs; [
      gnupg
      paperkey
      pgpdump
      parted
    ];
    
    # udev rules for GPG smartcard access
    services.udev.extraRules = ''
      # GPG SmartCard daemon
      SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart pcscd.service"
    '';
    
    # Environment variables for GPG
    environment.shellInit = ''
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
      ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
    '';
  };
}
```

# modules/nixos/security/yubikey/ssh.nix

```nix
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
```

# modules/nixos/security/yubikey/luks.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.luks.enable {
    # LUKS configuration for YubiKey
    boot.initrd = {
      # Enable YubiKey support in initrd
      availableKernelModules = [ "ykfde" ];
      
      # Install YubiKey tools in initrd
      extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.yubikey-personalization}/bin/ykchalresp
        copy_bin_and_libs ${pkgs.openssl}/bin/openssl
      '';
      
      # YubiKey LUKS unlock script
      extraUtilsCommandsTest = ''
        $out/bin/ykchalresp -V
      '';
    };
    
    # Install LUKS YubiKey tools
    environment.systemPackages = with pkgs; [
      cryptsetup
      yubikey-luks
    ];
    
    # systemd service for YubiKey LUKS
    systemd.services.yubikey-luks = {
      description = "YubiKey LUKS unlock service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
      };
    };
  };
}
```

# modules/nixos/security/yubikey/u2f.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.u2f.enable {
    # U2F authentication support
    hardware.u2f.enable = true;
    
    # Firefox U2F support
    programs.firefox = {
      enable = lib.mkDefault true;
      preferences = {
        "security.webauth.u2f" = true;
        "security.webauth.webauthn" = true;
        "security.webauth.webauthn_enable_softtoken" = false;
        "security.webauth.webauthn_enable_usbtoken" = true;
      };
    };
    
    # Chrome/Chromium U2F support
    programs.chromium = {
      enable = lib.mkDefault true;
      extensions = [
        # U2F extension ID (if needed for older versions)
        # "pfboblefjcgdjicmnffhdgionmgcdmne"
      ];
      extraOpts = {
        # Enable WebAuthn
        "WebAuthenticationProxySupport" = true;
      };
    };
    
    # Install U2F tools
    environment.systemPackages = with pkgs; [
      u2f-host
      libu2f-host
      pamu2fcfg
    ];
    
    # udev rules for U2F devices
    services.udev.packages = with pkgs; [
      libu2f-host
    ];
  };
}
```

# modules/nixos/security/yubikey/piv.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.yubikey.piv.enable {
    # PIV (Personal Identity Verification) support
    services.pcscd.enable = true;
    
    # PKCS#11 module for YubiKey PIV
    environment.variables = {
      PKCS11_MODULE = "${pkgs.yubico-piv-tool}/lib/libykcs11.so";
    };
    
    # Install PIV tools
    environment.systemPackages = with pkgs; [
      yubico-piv-tool
      pkcs11-tools
      opensc
    ];
    
    # Configure OpenSC for YubiKey PIV
    environment.etc."opensc.conf".text = ''
      app default {
        # YubiKey PIV configuration
        reader_driver yubico {
          # Enable PIV applet
          enable_pinpad = false;
        }
        
        framework pkcs15 {
          use_file_caching = true;
          pin_cache_counter = 10;
        }
      }
    '';
    
    # PIV certificate management
    security.pki = {
      certificateFiles = [
        # Add your PIV root certificates here
        # "/path/to/piv-root-ca.crt"
      ];
    };
    
    # Configure browsers for PIV certificates
    programs.firefox.preferences = {
      "security.tls.pkcs11.enable" = true;
      "security.default_personal_cert" = "Ask Every Time";
    };
  };
}
```

# modules/nixos/security/hardening/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./kernel.nix
    ./filesystem.nix
    ./network.nix
  ];
  
  options.mySystem.security.hardening = {
    enable = lib.mkEnableOption "system hardening";
    
    kernel.enable = lib.mkEnableOption "kernel hardening" // { default = true; };
    filesystem.enable = lib.mkEnableOption "filesystem hardening" // { default = true; };
    network.enable = lib.mkEnableOption "network hardening" // { default = true; };
    
    level = lib.mkOption {
      type = lib.types.enum [ "basic" "standard" "strict" ];
      default = "standard";
      description = "Hardening level to apply";
    };
  };
  
  config = lib.mkIf config.mySystem.security.hardening.enable {
    # Basic security settings
    security = {
      # Disable sudo password timeout
      sudo.execWheelOnly = true;
      
      # AppArmor (alternative to SELinux)
      apparmor = {
        enable = lib.mkDefault (config.mySystem.security.hardening.level != "basic");
        killUnconfinedConfinables = lib.mkDefault (config.mySystem.security.hardening.level == "strict");
      };
      
      # Disable unused authentication methods
      pam.enableSSHAgentAuth = false;
      
      # Restrict access to kernel logs
      dmesg.restrict = lib.mkDefault (config.mySystem.security.hardening.level != "basic");
      
      # Hide kernel pointers
      hideProcessInformation = lib.mkDefault (config.mySystem.security.hardening.level == "strict");
    };
    
    # System-wide security packages
    environment.systemPackages = with pkgs; [
      # Security scanning
      lynis
      chkrootkit
      rkhunter
      
      # Monitoring
      aide
      
      # Network security
      nmap
      wireshark-cli
    ] ++ lib.optionals (config.mySystem.security.hardening.level == "strict") [
      # Additional strict mode tools
      grsecurity-pax-utils
      checksec
    ];
    
    # Automatic security updates (careful with this!)
    system.autoUpgrade = lib.mkIf (config.mySystem.security.hardening.level == "strict") {
      enable = true;
      allowReboot = false;
      channel = "nixos-unstable";
      dates = "daily";
      flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
    };
  };
}
```

# modules/nixos/security/hardening/kernel.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.hardening.kernel.enable {
    # Kernel hardening parameters
    boot.kernelParams = [
      # Enable kernel address space layout randomization
      "kaslr"
      
      # Disable legacy ptrace access
      "kernel.yama.ptrace_scope=1"
      
      # Enable strict devkmem access
      "kernel.kptr_restrict=2"
      
      # Disable kexec (prevents kernel replacement)
      "kernel.kexec_load_disabled=1"
      
      # Disable user namespaces (if not needed)
      "user_namespace.enable=0"
      
      # Enable kernel stack randomization
      "randomize_kstack_offset=on"
      
      # Disable unprivileged eBPF
      "kernel.unprivileged_bpf_disabled=1"
      
      # Restrict BPF JIT compiler
      "net.core.bpf_jit_harden=2"
    ] ++ lib.optionals (config.mySystem.security.hardening.level == "strict") [
      # Strict mode additional parameters
      "kernel.dmesg_restrict=1"
      "kernel.perf_event_paranoid=3"
      "kernel.kptr_restrict=2"
      "net.ipv4.conf.all.log_martians=1"
      "net.ipv4.conf.default.log_martians=1"
    ];
    
    # Kernel sysctl hardening
    boot.kernel.sysctl = {
      # Kernel hardening
      "kernel.core_uses_pid" = 1;
      "kernel.ctrl-alt-del" = 0;
      "kernel.dmesg_restrict" = lib.mkIf (config.mySystem.security.hardening.level != "basic") 1;
      "kernel.kptr_restrict" = 2;
      "kernel.sysrq" = 0;
      "kernel.unprivileged_bpf_disabled" = 1;
      "kernel.yama.ptrace_scope" = 1;
      
      # Memory protection
      "vm.mmap_rnd_bits" = 32;
      "vm.mmap_rnd_compat_bits" = 16;
      
      # Network security (handled in network.nix as well)
      "net.core.bpf_jit_harden" = 2;
      
      # File system security
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;
    } // lib.optionalAttrs (config.mySystem.security.hardening.level == "strict") {
      # Additional strict mode sysctls
      "kernel.perf_event_paranoid" = 3;
      "kernel.printk" = "3 3 3 3";
      "vm.unprivileged_userfaultfd" = 0;
    };
    
    # Kernel modules blacklist
    boot.blacklistedKernelModules = [
      # Disable uncommon network protocols
      "dccp"
      "sctp" 
      "rds"
      "tipc"
      
      # Disable uncommon filesystems
      "cramfs"
      "freevxfs"
      "jffs2"
      "hfs"
      "hfsplus"
      "squashfs"
      "udf"
      
      # Disable firewire and USB storage if not needed
      # "firewire-core"
      # "usb-storage"
      
      # Disable bluetooth if not needed
      # "bluetooth"
    ] ++ lib.optionals (config.mySystem.security.hardening.level == "strict") [
      # Additional modules to disable in strict mode
      "vivid"  # Virtual video driver
      "n_hdlc" # HDLC line discipline
    ];
    
    # Use hardened kernel profile
    security.lockKernelModules = lib.mkDefault (config.mySystem.security.hardening.level == "strict");
    
    # Enable kernel guard
    boot.kernelPackages = lib.mkIf (config.mySystem.security.hardening.level == "strict") 
      pkgs.linuxPackages_hardened;
  };
}
```

# modules/nixos/security/hardening/filesystem.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.hardening.filesystem.enable {
    # Filesystem mount options hardening
    fileSystems = {
      # Secure /tmp with noexec and nosuid
      "/tmp" = lib.mkIf (!config.boot.tmp.useTmpfs) {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "noexec" "nosuid" "nodev" "size=2G" ];
      };
      
      # Secure /var/tmp
      "/var/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "noexec" "nosuid" "nodev" "size=1G" ];
      };
      
      # Secure /dev/shm
      "/dev/shm" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "noexec" "nosuid" "nodev" ];
      };
    };
    
    # Use tmpfs for /tmp by default
    boot.tmp = {
      useTmpfs = lib.mkDefault true;
      tmpfsSize = "50%";
      cleanOnBoot = true;
    };
    
    # Filesystem security sysctls
    boot.kernel.sysctl = {
      # Protect filesystem links
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      
      # Disable core dumps for SUID programs
      "fs.suid_dumpable" = 0;
    };
    
    # Secure file permissions
    security.sudo.configFile = ''
      # Secure PATH
      Defaults secure_path="/run/wrappers/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      
      # Require a password for all commands
      Defaults timestamp_timeout=0
      
      # Log all sudo commands
      Defaults logfile="/var/log/sudo.log"
      Defaults log_input,log_output
    '';
    
    # File integrity monitoring with AIDE
    environment.systemPackages = with pkgs; [ aide ];
    
    # AIDE configuration
    environment.etc."aide.conf".text = ''
      # AIDE configuration for file integrity monitoring
      database=file:/var/lib/aide/aide.db
      database_out=file:/var/lib/aide/aide.db.new
      gzip_dbout=yes
      
      # Rules
      R = p+i+n+u+g+s+m+c+md5+sha256
      L = p+i+n+u+g
      
      # Directories to monitor
      /bin R
      /sbin R
      /usr/bin R
      /usr/sbin R
      /etc R
      /boot R
      
      # Exclude volatile directories
      !/var/log
      !/var/tmp
      !/tmp
      !/proc
      !/sys
      !/dev
    '';
    
    # SystemD service for AIDE
    systemd.services.aide-check = lib.mkIf (config.mySystem.security.hardening.level != "basic") {
      description = "AIDE file integrity check";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.aide}/bin/aide --check";
        User = "root";
      };
    };
    
    systemd.timers.aide-check = lib.mkIf (config.mySystem.security.hardening.level != "basic") {
      description = "Run AIDE file integrity check daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
```

# modules/nixos/security/hardening/network.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.security.hardening.network.enable {
    # Network security sysctls
    boot.kernel.sysctl = {
      # IP Forwarding
      "net.ipv4.ip_forward" = 0;
      "net.ipv6.conf.all.forwarding" = 0;
      
      # Source routing
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;
      
      # ICMP redirects
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      
      # Log suspicious packets
      "net.ipv4.conf.all.log_martians" = lib.mkIf (config.mySystem.security.hardening.level != "basic") 1;
      "net.ipv4.conf.default.log_martians" = lib.mkIf (config.mySystem.security.hardening.level != "basic") 1;
      
      # Ignore ICMP ping requests
      "net.ipv4.icmp_echo_ignore_all" = lib.mkIf (config.mySystem.security.hardening.level == "strict") 1;
      "net.ipv6.icmp.echo_ignore_all" = lib.mkIf (config.mySystem.security.hardening.level == "strict") 1;
      
      # Ignore ICMP broadcasts
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      
      # Ignore bogus ICMP error responses
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      
      # Reverse path filtering
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      
      # TCP hardening
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.tcp_fin_timeout" = 15;
      "net.ipv4.tcp_keepalive_time" = 300;
      "net.ipv4.tcp_keepalive_probes" = 5;
      "net.ipv4.tcp_keepalive_intvl" = 15;
      
      # IPv6 privacy extensions
      "net.ipv6.conf.all.use_tempaddr" = 2;
      "net.ipv6.conf.default.use_tempaddr" = 2;
      
      # Disable IPv6 router advertisements
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.default.accept_ra" = 0;
      
      # BPF JIT hardening
      "net.core.bpf_jit_harden" = 2;
      
      # Netfilter connection tracking
      "net.netfilter.nf_conntrack_max" = 65536;
      "net.netfilter.nf_conntrack_tcp_timeout_established" = 1800;
    } // lib.optionalAttrs (config.mySystem.security.hardening.level == "strict") {
      # Additional strict mode network settings
      "net.ipv4.conf.all.arp_ignore" = 1;
      "net.ipv4.conf.all.arp_announce" = 2;
      "net.ipv4.tcp_challenge_ack_limit" = 999999999;
    };
    
    # Enhanced firewall configuration
    networking.firewall = {
      enable = true;
      
      # Default deny policy
      rejectPackets = true;
      
      # Rate limiting for SSH
      extraCommands = ''
        # Rate limit SSH connections
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
        
        # Drop invalid packets
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
        
        # Log dropped packets (optional)
        ${lib.optionalString (config.mySystem.security.hardening.level != "basic") ''
        iptables -A INPUT -j LOG --log-prefix "DROPPED: " --log-level 4
        ''}
      '';
      
      extraStopCommands = ''
        iptables -F
        iptables -X
      '';
    };
    
    # Disable unused network services
    services = {
      # Disable if not needed
      avahi.enable = lib.mkDefault false;
      printing.enable = lib.mkDefault false;
      
      # Configure SSH securely
      openssh = lib.mkIf config.services.openssh.enable {
        settings = {
          # Protocol and encryption
          Protocol = 2;
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
            "aes128-gcm@openssh.com"
            "aes256-ctr"
            "aes192-ctr"
            "aes128-ctr"
          ];
          
          MACs = [
            "hmac-sha2-256-etm@openssh.com"
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256"
            "hmac-sha2-512"
          ];
          
          KexAlgorithms = [
            "curve25519-sha256"
            "curve25519-sha256@libssh.org"
            "diffie-hellman-group16-sha512"
            "diffie-hellman-group18-sha512"
            "diffie-hellman-group-exchange-sha256"
          ];
          
          # Security settings
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          ChallengeResponseAuthentication = false;
          PubkeyAuthentication = true;
          X11Forwarding = false;
          AllowTcpForwarding = lib.mkIf (config.mySystem.security.hardening.level == "strict") "no";
          AllowAgentForwarding = lib.mkIf (config.mySystem.security.hardening.level == "strict") "no";
          
          # Connection limits
          MaxAuthTries = 3;
          ClientAliveInterval = 300;
          ClientAliveCountMax = 2;
          LoginGraceTime = 30;
          MaxSessions = 2;
          MaxStartups = "10:30:60";
        };
        
        # Additional hardening
        extraConfig = ''
          # Additional SSH hardening
          DebianBanner no
          VersionAddendum none
          
          # Restrict users/groups
          AllowUsers ${config.mySystem.users.mainUser}
          DenyUsers root
          
          # Use privilege separation
          UsePrivilegeSeparation yes
          
          # Disable unused features
          GatewayPorts no
          PermitTunnel no
          PermitUserEnvironment no
        '';
      };
    };
    
    # Network monitoring tools
    environment.systemPackages = with pkgs; [
      # Network analysis
      tcpdump
      wireshark-cli
      nmap
      netcat-gnu
      
      # Security scanning
      nikto
      
      # Traffic monitoring
      iftop
      nethogs
      vnstat
    ] ++ lib.optionals (config.mySystem.security.hardening.level == "strict") [
      # Additional tools for strict mode
      masscan
      zmap
    ];
    
    # Fail2ban for intrusion prevention
    services.fail2ban = lib.mkIf (config.mySystem.security.hardening.level != "basic") {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
      
      jails = {
        ssh = {
          enabled = true;
          filter = "sshd";
          action = "iptables-multiport[name=SSH, port=ssh, protocol=tcp]";
          maxretry = 5;
          findtime = 600;
          bantime = 3600;
        };
      };
    };
  };
}
```

# modules/nixos/security/certificates/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./ca-certificates.nix
    ./ssl.nix
  ];
  
  options.mySystem.security.certificates = {
    enable = lib.mkEnableOption "certificate management" // { default = true; };
    
    customCAs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Custom CA certificates to install";
    };
    
    ssl = {
      enable = lib.mkEnableOption "SSL/TLS configuration" // { default = true; };
      
      protocols = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "TLSv1.2" "TLSv1.3" ];
        description = "Allowed SSL/TLS protocols";
      };
      
      ciphers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "ECDHE-ECDSA-AES256-GCM-SHA384"
          "ECDHE-RSA-AES256-GCM-SHA384"
          "ECDHE-ECDSA-CHACHA20-POLY1305"
          "ECDHE-RSA-CHACHA20-POLY1305"
          "ECDHE-ECDSA-AES128-GCM-SHA256"
          "ECDHE-RSA-AES128-GCM-SHA256"
        ];
        description = "Allowed SSL/TLS ciphers";
      };
    };
  };
  
  config = lib.mkIf config.mySystem.security.certificates.enable {
    # Install certificate management tools
    environment.systemPackages = with pkgs; [
      openssl
      gnutls
      ca-certificates
      
      # Certificate utilities
      certbot
      step-cli
      
      # PKCS tools
      pkcs11-tools
      softhsm
    ];
    
    # Install custom CA certificates
    security.pki.certificateFiles = config.mySystem.security.certificates.customCAs;
    
    # Enable certificate services
    services.certbot = {
      enable = lib.mkDefault false;  # Enable per-host as needed
    };
  };
}