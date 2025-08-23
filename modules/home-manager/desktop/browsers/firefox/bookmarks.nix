{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.desktop.browsers.firefox.bookmarks.enable {
    programs.firefox.profiles.${config.myHome.desktop.browsers.firefox.profile.name} = {
      bookmarks = [
        {
          name = "Development";
          toolbar = true;
          bookmarks = [
            {
              name = "GitHub";
              url = "https://github.com";
            }
            {
              name = "GitLab";
              url = "https://gitlab.com";
            }
            {
              name = "Stack Overflow";
              url = "https://stackoverflow.com";
            }
            {
              name = "MDN Web Docs";
              url = "https://developer.mozilla.org";
            }
          ];
        }
        {
          name = "NixOS";
          toolbar = true;
          bookmarks = [
            {
              name = "NixOS Manual";
              url = "https://nixos.org/manual/nixos/stable/";
            }
            {
              name = "Nixpkgs Manual";
              url = "https://nixos.org/manual/nixpkgs/stable/";
            }
            {
              name = "Home Manager Manual";
              url = "https://nix-community.github.io/home-manager/";
            }
            {
              name = "NixOS Search";
              url = "https://search.nixos.org";
            }
            {
              name = "Nix Package Versions";
              url = "https://lazamar.co.uk/nix-versions/";
            }
          ];
        }
        {
          name = "Tools";
          toolbar = false;
          bookmarks = [
            {
              name = "Regex101";
              url = "https://regex101.com";
            }
            {
              name = "Can I Use";
              url = "https://caniuse.com";
            }
            {
              name = "JSON Formatter";
              url = "https://jsonformatter.curiousconcept.com";
            }
          ];
        }
      ];
    };
  };
}
