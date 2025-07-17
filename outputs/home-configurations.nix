{
  homeConfigurations = let
    # Get all homes from the directory structure
    homes = (import ../lib/mk-homes.nix { lib = inputs.nixpkgs.lib; }) ../homes;
    
    # Create a home-manager configuration for each home
    mkHome = name: homeConfig: inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        (homeConfig inputs)
      ];
    };
  in
    builtins.mapAttrs mkHome homes;
}
