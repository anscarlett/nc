{
  home-manager = {
    url = let constants = import ../lib/constants.nix; in "github:nix-community/home-manager/${constants.nixVersion}";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
