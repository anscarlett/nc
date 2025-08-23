{
  description = "Minimal NixOS configuration with YubiKey security";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sopsnix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      lib = import ./lib { inherit (nixpkgs) lib; };
    in {
      # Auto-discovered NixOS configurations
      nixosConfigurations = lib.mkNixosConfigurations {
        inherit inputs;
        hostsDir = ./hosts;
      };

      # Auto-discovered Home Manager configurations  
      homeConfigurations = lib.mkHomeConfigurations {
        inherit inputs;
        usersDir = ./users;
      };

      # Development shells
      devShells = lib.mkDevShells { inherit inputs nixpkgs; };
      
      # Export lib for private repos
      inherit lib;
    };
}
