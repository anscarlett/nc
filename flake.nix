{
  description = "NixOS system configuration";

  inputs = {
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    yubikey-guide = {
      url = "github:drduh/YubiKey-Guide";
      flake = false;
    };
    sopsnix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    homeConfigurations = (import ./outputs/home-configurations.nix) inputs;
    nixosConfigurations = (import ./outputs/nixos-configurations.nix) inputs;
    
    # Export lib and modules for use by private configs
    lib = import ./lib { lib = inputs.nixpkgs.lib; };
    modules = {
      core = ./modules/core;
      desktop = {
        dwm = ./modules/desktop/dwm;
        gnome = ./modules/desktop/gnome;
        hyprland = ./modules/desktop/hyprland;
        kde = ./modules/desktop/kde;
      };
      disko-presets = {
        btrfs-flex = ./modules/disko-presets/btrfs-flex.nix;
        lvm-basic = ./modules/disko-presets/lvm-basic.nix;
      };
      installer = ./modules/installer;
      server = ./modules/server;
    };
  };
}