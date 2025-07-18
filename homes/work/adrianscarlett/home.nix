# Work home configuration for Adrian Scarlett
inputs: { pkgs, lib, config, ... }: let
  nameFromPath = import ../../../lib/get-name-from-path.nix { inherit lib; };
  username = nameFromPath.getUsername ./.;  # This gives us "adrianscarlett-work"
in {
  home = {
    # Set username when running standalone, but NixOS will override this
    username = lib.mkDefault username;
    homeDirectory = "/home/${username}";
    stateVersion = (import ../../../lib/constants.nix).nixVersion;
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Set required paths for accounts modules
  accounts.calendar.basePath = "${config.home.homeDirectory}/.local/share/calendars";
  accounts.contact.basePath = "${config.home.homeDirectory}/.local/share/contacts";
  accounts.email.maildirBasePath = "${config.home.homeDirectory}/.local/share/mail";

  # Work-specific configurations
  programs.git = {
    enable = true;
    userName = "Adrian Scarlett";
    userEmail = "adrian.scarlett@work.com";
  };
  
  # Example: Work SSH configuration (uncomment when you set up secrets)
  # programs.ssh = {
  #   enable = true;
  #   matchBlocks = {
  #     "work-server" = {
  #       hostname = "internal.company.com";
  #       user = "ascarlett";
  #       identityFile = config.age.secrets.ssh-work-key.path;
  #     };
  #   };
  # };
  
  # Example: User-level secrets (uncomment when you set up secrets)
  # age.secrets.ssh-work-key = {
  #   file = ./ssh-work-key.age;
  #   path = "${config.home.homeDirectory}/.ssh/work_key";
  # };
  # Secrets definitions are in ./secrets.nix
}
