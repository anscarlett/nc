inputs: {
  nixosConfigurations = let
    # Get all hosts from the directory structure
    hosts = (import ../lib/mk-hosts.nix { lib = inputs.nixpkgs.lib; }) ../hosts;
    
    # Create a NixOS system for each host
    mkHost = name: hostConfig: inputs.nixpkgs.lib.nixosSystem {
      inherit (hostConfig) system;
      modules = hostConfig.modules ++ [
        inputs.agenix.nixosModules.default
      ];
    };
  in
    builtins.mapAttrs mkHost hosts;
}
