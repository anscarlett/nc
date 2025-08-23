# Example host configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Import core modules
  imports = [
    ../../modules/core.nix
    ../../modules/desktop.nix
    (import ../../modules/disko.nix {
      disk = "/dev/nvme0n1";  # CHANGE THIS TO YOUR DISK!
      luksName = "cryptroot";
      enableYubikey = true;
    })
  ];

  # Hostname (auto-detected from folder name: "example")
  networking.hostName = "example";

  # Hardware configuration (adjust for your hardware)
  boot.initrd.availableKernelModules = [ 
    "xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" 
  ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"

  # Graphics
  hardware.graphics.enable = true;
  # hardware.nvidia.modesetting.enable = true; # Uncomment for NVIDIA

  # User password (generate with: mkpasswd -m sha-512)
  users.users.example.hashedPassword = "$6$CHANGEME"; # CHANGE THIS!

  # Example secrets (uncomment when needed)
  # sops.secrets.wifi-password = {
  #   sopsFile = ./secrets.yaml;
  #   owner = "root";
  #   group = "networkmanager";
  # };

  # Example network configuration using secrets
  # networking.wireless.networks = {
  #   "MyWiFi" = {
  #     pskRaw = config.sops.secrets.wifi-password.path;
  #   };
  # };

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # Add host-specific packages here
  ];
}