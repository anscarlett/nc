# DWM (Dynamic Window Manager) configuration
{ config, pkgs, lib, ... }: {
  # Import base desktop configuration
  imports = [ ../. ];

  # Enable simple display manager
  services.xserver = {
    displayManager = {
      lightdm.enable = true;
      defaultSession = "none+dwm";
    };
    windowManager.dwm.enable = true;
  };

  # DWM-specific packages
  environment.systemPackages = with pkgs; [
    dmenu          # Application launcher
    st             # Simple terminal
    slock          # Screen locker
    xorg.xsetroot  # For status bar
    # Status bar utilities
    acpi           # Battery info
    pamixer        # Volume control
    brightnessctl  # Brightness control
  ];

  # Build dwm with custom patches and config
  nixpkgs.overlays = [
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: {
        # Add your patches here
        patches = [
          # Example: ./patches/dwm-systray.diff
        ];
        # Custom config.h
        postPatch = '''
          cp ${./config.h} config.h
        ''';
      });
    })
  ];
}
