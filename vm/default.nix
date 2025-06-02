# VM configuration for testing
{ pkgs, lib, ... }:

{
  # Enable SSH for easy access
  services.openssh.enable = true;
  
  # VM-specific settings
  virtualisation = {
    memorySize = 4096; # MB
    cores = 2;
    # Use SPICE for better VM integration
    spiceUSBRedirection.enable = true;
    # Enable QXL video driver
    qemu.options = [ "-vga qxl" ];
  };

  # Basic system configuration
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  # Allow passwordless sudo for easier testing
  security.sudo.wheelNeedsPassword = false;
}
