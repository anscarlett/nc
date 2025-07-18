{
  description = "Private NixOS Configuration";

  inputs = {
    # Import the public configuration
    public-config = {
      url = "github:anscarlett/nc";
      # Or if using a different branch/tag:
      # url = "github:anscarlett/nc/main";
    };
    
    # You can also override inputs from the public config
    nixpkgs.follows = "public-config/nixpkgs";
    home-manager.follows = "public-config/home-manager";
    
    # All other inputs (agenix, disko, etc.) come from public-config
  };

  outputs = { self, public-config, ... }@inputs: {
    # Use public repo's output functions to generate configurations from our local files
    nixosConfigurations = ((import "${public-config}/outputs/nixos-configurations.nix") inputs);
    homeConfigurations = ((import "${public-config}/outputs/home-configurations.nix") inputs);

    # Re-export useful things from public config
    lib = public-config.lib;
    modules = public-config.modules;
  };
}
