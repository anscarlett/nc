# outputs/install.nix
{ self, nixpkgs, disko, nixos-anywhere, ... }:
{
  # Installation packages
  packages = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system: {
    install-vm = nixpkgs.legacyPackages.${system}.writeShellApplication {
      name = "install-vm";
      runtimeInputs = [
        nixos-anywhere.packages.${system}.default
      ];
      text = ''
        # Mount the host directory to access our config
        mkdir -p /mnt/host
        mount -t 9p -o trans=virtio,version=9p2000.L host /mnt/host
        cd /mnt/host

        # Install using nixos-anywhere
        nixos-anywhere --flake .#vm \
          --disk-encryption-keys "" \
          root@localhost
      '';
    };
  });
}
