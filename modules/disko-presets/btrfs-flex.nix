{ disk ? "/dev/disk/by-id/your-disk"
, enableImpermanence ? false
, enableHibernate ? false
, swapSize ? null
, luksName ? "cryptroot"
, subvolumes ? [ "@" "@home" "@nix" "@persist" ]
, enableYubikey ? false
, enableSopsSecrets ? false
}:

{
  disko.devices = {
    disk = {
      main = {
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
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                } // (if enableYubikey then {
                  # YubiKey LUKS configuration
                  # This requires the YubiKey to be set up with a LUKS key slot
                  # Use: cryptsetup luksAddKey /dev/disk/by-id/your-disk --key-slot 1
                  keyFile = "/dev/disk/by-id/usb-Yubico_YubiKey_*";
                  keyFileSize = 32;
                  keyFileOffset = 0;
                  fallbackToPassword = true;
                } else {});
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@" = { 
                      mountpoint = "/";
                      mountOptions = if enableImpermanence then 
                        ["subvol=@" "noatime" "compress=zstd" "discard=async"]
                      else ["subvol=@"];
                    };
                    "@home" = { 
                      mountpoint = "/home";
                      mountOptions = ["subvol=@home"];
                    };
                    "@nix" = { 
                      mountpoint = "/nix";
                      mountOptions = ["subvol=@nix"];
                    };
                    "@persist" = { 
                      mountpoint = "/persist";
                      mountOptions = ["subvol=@persist"];
                    };
                  } // (if enableSopsSecrets then {
                    "@secrets" = { 
                      mountpoint = "/persist/secrets"; 
                      mountOptions = ["subvol=@secrets"];
                    };
                  } else {});
                };
              };
            };
          };
        };
      };
    };
  } // (if enableHibernate && swapSize != null then {
    lvm_vg = { 
      swap_vg = { 
        type = "lvm_vg"; 
        lvs = { 
          swap = { 
            size = swapSize; 
            content.type = "swap"; 
          }; 
        }; 
      }; 
    };
  } else {});
}
