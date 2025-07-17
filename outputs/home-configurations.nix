inputs:
{
  homeConfigurations = let
    homes = (import ../lib/mk-homes.nix { lib = inputs.nixpkgs.lib; }) ../homes;
    mkHome = name: homeConfig: inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        (homeConfig inputs)
      ];
    };
  in
    builtins.mapAttrs mkHome homes;
}
