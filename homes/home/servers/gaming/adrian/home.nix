# Gaming server configuration for Adrian
inputs: { pkgs, ... }: {
  home = {
    username = "adrian";
    homeDirectory = "/home/adrian";
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

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Gaming server specific configurations
  programs.git = {
    enable = true;
    userName = "Adrian";
    userEmail = "gaming@email.com";
  };
}
