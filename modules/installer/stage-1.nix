# Early boot stage configuration for 9P support
{ config, lib, pkgs, ... }:

{
  boot.initrd = {
    # Enable 9P support in initrd
    kernelModules = [ "9p" "9pnet" "9pnet_virtio" "virtio_pci" ];
    
    # Make sure virtio modules are available
    availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" "9p" "9pnet" "9pnet_virtio" ];

    # Mount host directory in stage 1
    postMountCommands = ''
      mkdir -p /mnt-root/mnt/host
      mount -t 9p -o trans=virtio,version=9p2000.L host /mnt-root/mnt/host
    '';
  };
}
