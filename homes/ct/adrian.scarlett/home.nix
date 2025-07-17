# CT work configuration for Adrian Scarlett
inputs: { pkgs, ... }: {
  home = {
    username = "adrian.scarlett";
    homeDirectory = "/home/adrian.scarlett";
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

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Work-specific configurations
  programs.git = {
    enable = true;
    userName = "Adrian Scarlett";
    userEmail = "adrian.scarlett@company.com";
  };
}
