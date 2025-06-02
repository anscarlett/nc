{
  nixpkgs.url = let constants = import ../lib/constants.nix; in "github:NixOS/nixpkgs/${constants.nixVersion}";
}
