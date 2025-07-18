# Work-specific home configuration
inputs: { config, lib, pkgs, ... }:

let
  # Use the public repo's function to get username from folder structure
  nameFromPath = import "${inputs.public-config}/lib/get-name-from-path.nix" { inherit lib; };
  username = nameFromPath.getUsername ./.;  # Automatically derived from folder path
in {
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
  
  # Import base home configuration from public repo if available
  imports = [
    # You can reference shared home modules if you create them
  ];

  # Work-specific home configuration
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@company.com";
    
    # Work-specific git config
    extraConfig = {
      # core.sshCommand = "ssh -i ~/.ssh/work_key";  # If using work SSH key
    };
  };

  # Work SSH configuration (uncomment when needed)
  # programs.ssh = {
  #   enable = true;
  #   matchBlocks = {
  #     "work-server" = {
  #       hostname = "internal.company.com";
  #       user = username;
  #       identityFile = config.age.secrets.ssh-work-key.path;  # User-level secret
  #     };
  #   };
  # };
  
  # User-level secrets (managed by Home Manager/agenix) - defined in ./secrets.nix
  # age.secrets.ssh-work-key = {
  #   file = ./ssh-work-key.age;
  #   path = "${config.home.homeDirectory}/.ssh/work_key";
  # };
  # age.secrets.api-tokens = {
  #   file = ./api-tokens.age;
  #   path = "${config.home.homeDirectory}/.config/work-tokens";
  # };

  # Work-specific shell aliases
  programs.zsh.shellAliases = {
    # work-vpn = "sudo systemctl start corporate-vpn";
    # work-off = "sudo systemctl stop corporate-vpn";
    ll = "ls -la";
    la = "ls -la";
  };

  # Work-specific packages for user environment
  home.packages = with pkgs; [
    # Add user-specific packages here
    # jetbrains.idea-ultimate
    # postman
    # docker-compose
  ];
}
