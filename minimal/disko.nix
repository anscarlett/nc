# Disko configuration for Btrfs + LUKS + YubiKey
{ disk ? throw "You must set 'disk' parameter (e.g., /dev/nvme0n1)"
, luksName ? "cryptroot"
, enableYubikey ? true
, swapSize ? "8G"
}:

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = disk;
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = luksName;
              settings.allowDiscards = true;
              
              # YubiKey challenge-response unlock
              passwordFile = if enableYubikey then "/tmp/yubikey-luks.key" else null;
              
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                
                subvolumes = {
                  # Root subvolume - wiped on boot with impermanence
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Nix store - persistent
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Persistent data
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Logs
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  
                  # Swap
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = [ "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Swap file
  swapDevices = [{
    device = "/swap/swapfile";
    size = 8192; # 8GB default
  }];

  # Impermanence configuration
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/NetworkManager"
      "/etc/nixos"
      "/etc/ssh"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    users.example = {
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
        ".config"
        ".local"
        ".ssh"
        ".gnupg"
      ];
    };
  };

  # YubiKey LUKS unlock script
  boot.initrd.postDeviceCommands = lib.mkIf enableYubikey ''
    echo "Attempting YubiKey LUKS unlock..."
    if ${pkgs.yubikey-manager}/bin/ykman otp calculate 2 "$(echo -n '${luksName}' | ${pkgs.xxd}/bin/xxd -p)" > /tmp/response 2>/dev/null; then
      echo -n "$(cat /tmp/response)" | ${pkgs.xxd}/bin/xxd -r -p > /tmp/yubikey-luks.key
      echo "YubiKey response generated"
    else
      echo "YubiKey not found or error - falling back to password"
      echo -n "fallback" > /tmp/yubikey-luks.key
    fi
  '';
}