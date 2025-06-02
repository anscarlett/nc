# Gaming server configuration for Adrian
inputs: { pkgs, ... }: {
  home = let
    username = (import ../../../../../lib/get-name-from-path.nix { lib = inputs.nixpkgs.lib }).getUsername ./.;
  in {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = (import ../../../../../lib/constants.nix).nixVersion;
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Gaming server specific configurations
  programs.git = {
    enable = true;
    userName = "Adrian";
    userEmail = "gaming@email.com";
  };
}
