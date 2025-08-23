# Desktop configuration - Hyprland + essentials
{ config, pkgs, lib, ... }:

{
  # Hyprland Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Audio - PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Essential desktop packages
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    waybar wofi alacritty
    wl-clipboard grim slurp
    swaylock-effects mako
    
    # Applications
    firefox bitwarden
    
    # System utilities
    pavucontrol networkmanagerapplet
    libnotify xdg-utils
  ];

  # XDG portal for screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Default Hyprland configuration
  environment.etc."hypr/hyprland.conf".text = ''
    # Minimal Hyprland config
    monitor=,preferred,auto,1

    # Autostart
    exec-once = waybar & mako &

    # Input
    input {
        kb_layout = gb
        follow_mouse = 1
        touchpad.natural_scroll = false
    }

    # Appearance
    general {
        gaps_in = 5
        gaps_out = 10
        border_size = 2
        col.active_border = rgba(33ccffee)
        col.inactive_border = rgba(595959aa)
        layout = dwindle
    }

    decoration {
        rounding = 5
        blur.enabled = true
        drop_shadow = true
    }

    # Key bindings
    $mod = SUPER

    bind = $mod, Q, exec, alacritty
    bind = $mod, C, killactive
    bind = $mod, M, exit
    bind = $mod, R, exec, wofi --show drun
    bind = $mod, V, togglefloating
    bind = $mod, L, exec, swaylock-effects

    # Workspaces
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5

    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5

    # Move focus
    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d
  '';

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
  };

  # Stylix theming
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tomorrow-night.yaml";
    image = pkgs.fetchurl {
      url = "https://images.unsplash.com/photo-1518837695005-2083093ee35b";
      hash = "sha256-IkfNDClX/u6XCQHVNp0R8TJkFx5mApPFCeZS4cP4Kjc=";
    };
  };
}
