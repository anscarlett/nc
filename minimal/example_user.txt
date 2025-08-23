# Example user configuration
{ config, pkgs, lib, ... }:

{
  home = {
    username = "example";
    homeDirectory = "/home/example";
    stateVersion = "25.05";
  };

  # Essential programs
  programs = {
    home-manager.enable = true;
    
    # Git configuration
    git = {
      enable = true;
      userName = "Your Name";                    # CHANGE THIS
      userEmail = "your.email@example.com";     # CHANGE THIS
    };
    
    # ZSH shell
    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        ".." = "cd ..";
        gs = "git status";
        ga = "git add";
        gc = "git commit";
      };
    };
    
    # Alacritty terminal
    alacritty = {
      enable = true;
      settings = {
        window.opacity = 0.9;
        font.size = 12;
      };
    };
    
    # Firefox browser
    firefox.enable = true;
  };

  # User packages
  home.packages = with pkgs; [
    # Development
    vscode
    
    # Utilities
    htop tree file
    zip unzip
    
    # Media
    mpv imv
  ];

  # Impermanence - persist user data
  home.persistence."/persist/home/example" = {
    directories = [
      "Documents"
      "Downloads" 
      "Pictures"
      "Videos"
      ".config"
      ".local"
      ".ssh"
      ".gnupg"
    ];
    allowOther = true;
  };

  # Example secrets (uncomment when setting up)
  # sops.secrets.ssh-key = {
  #   sopsFile = ./secrets.yaml;
  #   path = "${config.home.homeDirectory}/.ssh/id_rsa";
  # };
}