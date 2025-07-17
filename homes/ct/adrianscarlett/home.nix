# CT work configuration for Adrian Scarlett
inputs: { pkgs, lib, ... }: let
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  username = nameFromPath.getUsername ./.;  # This gives us "adrianscarlett-ct"
in {
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = (import ../../../lib/constants.nix).nixVersion;
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Work-specific configurations
  programs.git = {
    enable = true;
    userName = "Adrian Scarlett";
    userEmail = "adrian.scarlett@company.com";
  };
}
