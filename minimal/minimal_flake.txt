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
    lib = nixpkgs.lib;
    
    # Pure function to get hostname from path
    getHostname = path:
      let
        pathStr = toString path;
        parts = lib.splitString "/" pathStr;
        # Get the last directory name (the hostname)
        hostname = lib.last (builtins.filter (x: x != "" && x != ".") parts);
      in hostname;
    
    # Pure function to get username from path  
    getUsername = path:
      let
        pathStr = toString path;
        parts = lib.splitString "/" pathStr;
        # Get the last directory name (the username)
        username = lib.last (builtins.filter (x: x != "" && x != ".") parts);
      in username;

    # Determine system architecture from hostname patterns
    getSystemArch = hostname:
      if lib.hasInfix "rock5b" hostname || lib.hasInfix "rpi" hostname || lib.hasInfix "arm" hostname
      then "aarch64-linux"
      else "x86_64-linux";

    # Auto-discover hosts
    discoverHosts = 
      let
        hostsDir = ./hosts;
        hostDirs = if builtins.pathExists hostsDir
          then lib.filterAttrs (n: v: v == "directory") (builtins.readDir hostsDir)
          else {};
        
        mkHost = hostname: _:
          let
            hostPath = hostsDir + "/${hostname}";
            hostConfig = hostPath + "/host.nix";
            system = getSystemArch hostname;
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
      in
        builtins.listToAttrs (lib.mapAttrsToList mkHost hostDirs);

    # Auto-discover users
    discoverUsers = 
      let
        usersDir = ./users;
        userDirs = if builtins.pathExists usersDir
          then lib.filterAttrs (n: v: v == "directory") (builtins.readDir usersDir)
          else {};
        
        mkUser = username: _:
          let
            userPath = usersDir + "/${username}";
            userConfig = userPath + "/user.nix";
          in lib.nameValuePair username (import userConfig inputs);
      in
        builtins.listToAttrs (lib.mapAttrsToList mkUser userDirs);

    hosts = discoverHosts;
    users = discoverUsers;

  in {
    # NixOS configurations
    nixosConfigurations = builtins.mapAttrs (name: hostConfig:
      nixpkgs.lib.nixosSystem {
        inherit (hostConfig) system;
        specialArgs = { inherit inputs; inherit name; };
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

    # Standalone Home Manager configurations  
    homeConfigurations = builtins.mapAttrs (name: userConfig:
      let
        # Determine system from hostname patterns if possible, default to x86_64
        system = "x86_64-linux"; # Users can override in their config if needed
      in
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ userConfig ];
      }
    ) users;

    # Development shells for all supported systems
    devShells = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
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
    
    # Export lib functions for use in private repos
    lib = {
      inherit getHostname getUsername getSystemArch;
    };
  };
}