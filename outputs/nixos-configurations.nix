inputs:
let
  mkConfigs = import ../lib/mk-configs.nix { lib = inputs.nixpkgs.lib; };
  hosts = mkConfigs.mkHosts ../hosts;
  mkHost = name: hostConfig: inputs.nixpkgs.lib.nixosSystem {
    inherit (hostConfig) system;
    specialArgs = { inherit inputs; };
    modules = (map (module: 
      if builtins.isFunction module 
      then module inputs
      else module
    ) hostConfig.modules) ++ [
      inputs.agenix.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      inputs.sopsnix.nixosModules.sops
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
        };
      }
    ];
  };
  allHosts = hosts // {
    installer = {
      system = "x86_64-linux";
      modules = [
        (import ../hosts/installer/host.nix)
      ];
    };
  };
in
  builtins.mapAttrs mkHost allHosts
