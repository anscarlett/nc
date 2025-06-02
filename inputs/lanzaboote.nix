{
  lanzaboote = {
    url = "github:nix-community/lanzaboote/v0.3.0";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
  };
}
