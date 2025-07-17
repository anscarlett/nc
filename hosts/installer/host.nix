{ config, pkgs, ... }:
{
  # Minimal NixOS installer configuration
  boot.loader.grub.enable = false;
  services.sshd.enable = true;
  users.users.root.password = "nixos";
  # Add any other installer-specific options you want
}