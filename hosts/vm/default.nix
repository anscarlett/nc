# VM test configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../vm/default.nix
  ];

  # Basic system configuration
  system.stateVersion = "25.05";

  # Use the latest Linux kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Basic networking
  networking = {
    hostName = "nixos-vm";
    networkmanager.enable = true;
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];
}
