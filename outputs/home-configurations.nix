inputs:
let
  mkConfigs = import ../lib/mk-configs.nix { lib = inputs.nixpkgs.lib; };
  homes = mkConfigs.mkHomes ../homes;
  
  # Helper to determine system architecture from home path
  getSystemFromHome = homePath: 
    let
      pathStr = toString homePath;
    in
      if inputs.nixpkgs.lib.hasInfix "rock5b" pathStr then "aarch64-linux"
      else if inputs.nixpkgs.lib.hasInfix "rpi" pathStr || inputs.nixpkgs.lib.hasInfix "raspberry" pathStr then "aarch64-linux"
      else if inputs.nixpkgs.lib.hasInfix "aarch64" pathStr || inputs.nixpkgs.lib.hasInfix "arm64" pathStr then "aarch64-linux"
      else "x86_64-linux";  # Default to x86_64
  
  mkHome = name: homeConfig: 
    let
      # For now, default to x86_64-linux for home configs
      # In the future, this could be made smarter by looking at the home path
      system = "x86_64-linux";
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      modules = [
        # Only include the actual home config
        (homeConfig inputs)
      ];
    };
in
  builtins.mapAttrs mkHome homes

