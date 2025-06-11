{ device ? "/dev/disk/by-id/your-disk"
, enableImpermanence ? false
, enableHibernate ? false
, swapSize ? null
, luksName ? "cryptroot"
, subvolumes ? [ "@" "@home" "@nix" "@persist" ]
, enableYubikey ? false
}:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = device;
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
                ${enableYubikey ? "# Add Yubikey unlock options here (see disko/luks2 + tang/yubikey integration)" : ""}
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@" = { mountpoint = "/"; ${enableImpermanence ? "options = [\"subvol=@\" \"noatime\" \"compress=zstd\" \"discard=async\"];" : ""} };
                    "@home" = { mountpoint = "/home"; };
                    "@nix" = { mountpoint = "/nix"; };
                    "@persist" = { mountpoint = "/persist"; ${enableImpermanence ? "neededForBoot = true;" : ""} };
                  };
                };
              };
            };
          };
        };
      };
    };
    ${enableHibernate && swapSize != null ? 'lvm_vg = { swap_vg = { type = "lvm_vg"; lvs = { swap = { size = "' + swapSize + '"; content.type = "swap"; }; }; }; };' : ""}
  };
}
