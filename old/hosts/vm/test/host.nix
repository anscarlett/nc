# VM configuration for testing
inputs: { config, pkgs, lib, ... }: let
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  hostname = nameFromPath.getHostname ./.;
in {
  # System configuration
  system.stateVersion = "25.05";
  
  # VM-specific settings
  networking.hostName = hostname;
  
  networking.firewall.enable = false;

  # Boot configuration 
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  systemd.tmpfiles.rules = [
    "d /mnt/host-projects 0755 root root - -"
  ];

  # Allow FUSE usage
  boot.kernelModules = [ "fuse" "9p" "9pnet_virtio" ];
  environment.systemPackages = with pkgs; [ 
    btrfs-progs
    fuse 
    podman
    toolbox
  ];

  # VM filesystem configuration
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  
  fileSystems."/mnt/host-projects" = {
    device = "host_projects";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=262144"
      "cache=loose"
      "x-systemd.automount"
      "uid=0"
      "gid=0"
    ];
  };

  # Enable SSH for remote access
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;

  # Permissions for FUSE mounts
  services.udev.extraRules = ''
    KERNEL=="fuse", MODE="0666"
  '';

  virtualisation.podman.enable = true;
  virtualisation.diskSize = 50 * 1024;
  imports = [
    ../../../modules/core
    ../../../modules/desktop/hyprland
  ];
  
    # Users are automatically created by core module from homes directory
  # Override specific user settings
  # users.users.adrian-home.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  # users.users.adrianscarlett-work.hashedPassword = lib.mkForce "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  users.users.adrian-home = {
    password = lib.mkForce "adrian";
    isNormalUser = true;
    extraGroups = [ "wheel" "podman" ];
    # shell = pkgs.bash;
  };

  # Optional: AppArmor/Seccomp tweaking if needed
  security.apparmor.enable = false;
  # security.seccomp.enable = false;

  # Example: System-level secrets for testing (uncomment when needed)
  # age.secrets.test-data = {
  #   file = ./test-data.age;
  #   owner = "adrian";
  # };
  # Secrets definitions are in ./secrets.nix
}
