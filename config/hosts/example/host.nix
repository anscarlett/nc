# Example host configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Import core modules
  imports = [
    ../../modules/core.nix
    ../../modules/users.nix
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
  # users.users.example.hashedPassword = "YOUR_GENERATED_HASH_HERE";
  # 
  # REQUIRED: You MUST set a password hash before deploying!
  # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'

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
