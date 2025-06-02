# Installer module that sets up 9P filesystem mounting and installation tools
{ config, lib, pkgs, ... }:

{
  # Enable 9P filesystem support in the kernel
  boot.kernelModules = [ "9p" "9pnet" "9pnet_virtio" ];
  boot.supportedFilesystems = [ "9p" ];

  # Auto-mount the host directory
  fileSystems."/mnt/host" = {
    device = "host";
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "msize=104857600" ];
    neededForBoot = true;
  };

  # Create mount point during system activation
  system.activationScripts.createMountPoints = lib.stringAfter [ "var" ] ''
    mkdir -p /mnt/host
  '';

  # Add a convenient installation command
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "install-system" ''
      set -e
      echo "Installing NixOS from flake configuration..."
      cd /mnt/host
      
      # Check if we can access the flake
      if ! nix flake metadata >/dev/null 2>&1; then
        echo "Error: Cannot access flake configuration in /mnt/host"
        echo "Make sure you're running this from the NixOS installer environment"
        exit 1
      fi

      # Install using nixos-anywhere
      echo "Starting installation..."
      nix run github:nix-community/nixos-anywhere -- \
        --flake .#vm \
        --disk-encryption-keys "" \
        root@localhost

      echo "Installation complete! You can now reboot."
    '')
  ];
}
