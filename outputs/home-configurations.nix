inputs:
let
  mkConfigs = import ../lib/mk-configs.nix { lib = inputs.nixpkgs.lib; };
  homes = mkConfigs.mkHomes ../homes;
  mkHome = name: homeConfig: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      (homeConfig inputs)
    ];
  };
in
  builtins.mapAttrs mkHome homes

