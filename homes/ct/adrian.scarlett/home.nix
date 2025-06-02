# CT work configuration for Adrian Scarlett
inputs: { pkgs, ... }: {
  home = let
    username = (import ../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getUsername ./.;
  in {
    inherit username;
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
