# Configuration builder functions
{ lib }:

let
  utils = import ./utils.nix { inherit lib; };
in {
  # Build NixOS configurations from hosts directory
  mkNixosConfigurations = { inputs, hostsDir }:
    let
      hostDirs = utils.discoverDirs hostsDir;
      
      mkHost = hostname: _:
        let
          hostPath = hostsDir + "/${hostname}";
          hostConfig = hostPath + "/host.nix";
          system = utils.getSystemArch hostname;
        in lib.nameValuePair hostname {
          inherit system;
          modules = [ 
            (import hostConfig inputs)
            inputs.home-manager.nixosModules.home-manager
            inputs.disko.nixosModules.disko
            inputs.sopsnix.nixosModules.sops
            inputs.impermanence.nixosModules.impermanence
            inputs.stylix.nixosModules.stylix
          ];
        };

      hosts = builtins.listToAttrs (lib.mapAttrsToList mkHost hostDirs);
    in
      builtins.mapAttrs (name: hostConfig:
        inputs.nixpkgs.lib.nixosSystem {
          inherit (hostConfig) system;
          specialArgs = { inherit inputs name; };
          modules = hostConfig.modules ++ [
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        }
      ) hosts;

  # Build Home Manager configurations from users directory
  mkHomeConfigurations = { inputs, usersDir }:
    let
      userDirs = utils.discoverDirs usersDir;
      
      mkUser = username: _:
        let
          userPath = usersDir + "/${username}";
          userConfig = userPath + "/user.nix";
        in lib.nameValuePair username (import userConfig inputs);

      users = builtins.listToAttrs (lib.mapAttrsToList mkUser userDirs);
    in
      builtins.mapAttrs (name: userConfig:
        let
          system = "x86_64-linux"; # Default, can be overridden in user config
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          modules = [ userConfig ];
        }
      ) users;

  # Build development shells for all supported systems
  mkDevShells = { inputs, nixpkgs }:
    lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          yubikey-manager
          age
          sops
          mkpasswd
          git
          nixos-anywhere
        ];
      }
    );
}
