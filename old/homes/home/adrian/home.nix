# Personal home configuration for Adrian
inputs: { pkgs, lib, config, ... }: let
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  username = nameFromPath.getUsername ./.;  # This gives us "adrian-home"
in {
  home = {
    # Set username when running standalone, but NixOS will override this
    username = lib.mkDefault username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };


  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Set required paths for accounts modules
  accounts.calendar.basePath = "${config.home.homeDirectory}/.local/share/calendars";
  accounts.contact.basePath = "${config.home.homeDirectory}/.local/share/contacts";
  accounts.email.maildirBasePath = "${config.home.homeDirectory}/.local/share/mail";

  # Personal configurations
  programs.git = {
    enable = true;
    userName = "Adrian Scarlett";
    userEmail = "personal@email.com";
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    
    history = {
      size = 10000;
      path = "$HOME/.config/zsh/history";
    };
    
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";
      gd = "git diff";
    };
  };

  # Ensure the directory exists
  xdg.configFile."hypr/.keep".text = "";
}
