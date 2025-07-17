{ disk ? "/dev/disk/by-id/your-disk", vgName ? "vg", rootSize ? "100%FREE", swapSize ? null, homeSize ? null }:

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
            lvm = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = vgName;
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      ${vgName} = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = rootSize;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        } // (if swapSize != null then {
          swap = {
            size = swapSize;
            content.type = "swap";
          };
        } else {}) // (if homeSize != null then {
          home = {
            size = homeSize;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
            };
          };
        } else {});
      };
    };
  };
}
