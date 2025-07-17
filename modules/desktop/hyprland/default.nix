# Hyprland Wayland compositor configuration
{ config, pkgs, lib, ... }: {
  # Import base desktop configuration
  imports = [ ../. ];

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Wayland-specific packages including setup script
  environment.systemPackages = with pkgs; [
    waybar          # Status bar
    swww            # Wallpaper daemon
    swaylock-fancy  # Lock screen
    wl-clipboard    # Clipboard
    mako           # Notification daemon for Wayland
    wofi           # Application launcher
    grim           # Screenshot utility
    slurp          # Screen area selection
    xfce.thunar    # File manager
    alacritty      # Terminal (ensure it's available)
    wev            # Wayland event viewer for testing keys
    
    (writeShellScriptBin "start-hyprland" ''
      echo "Starting Hyprland manually..."
      export XDG_SESSION_TYPE=wayland
      export XDG_CURRENT_DESKTOP=Hyprland
      export XDG_SESSION_DESKTOP=Hyprland
      exec Hyprland
    '')
    
    (writeShellScriptBin "test-keys" ''
      echo "Testing key detection..."
      echo "Press Ctrl+C to exit"
      exec wev
    '')
    
    (writeShellScriptBin "setup-hypr-config" ''
      echo "Setting up Hyprland config..."
      mkdir -p ~/.config/hypr
      cp /etc/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
      echo "Config copied to ~/.config/hypr/hyprland.conf"
      echo "Try Super+R now!"
    '')
  ];

  # Enable XDG portal for screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Create default Hyprland config for all users
  environment.etc."hypr/hyprland.conf".text = ''
    # Basic Hyprland configuration for VM testing
    monitor=,1920x1080@60,0x0,1

    # Execute on startup
    exec-once = waybar &
    exec-once = mako &
    exec-once = swww init

    # Environment variables
    env = XCURSOR_SIZE,24

    # Input configuration
    input {
        kb_layout = gb
        follow_mouse = 1
        touchpad {
            natural_scroll = false
        }
        sensitivity = 0
    }

    # General configuration
    general {
        gaps_in = 5
        gaps_out = 10
        border_size = 2
        col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
        col.inactive_border = rgba(595959aa)
        layout = dwindle
    }

    # Window decoration
    decoration {
        rounding = 10
        blur {
            enabled = true
            size = 3
            passes = 1
        }
        drop_shadow = yes
        shadow_range = 4
        shadow_render_power = 3
        col.shadow = rgba(1a1a1aee)
    }

    # Animation configuration
    animations {
        enabled = yes
        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
    }

    # Layout configuration
    dwindle {
        pseudotile = yes
        preserve_split = yes
    }

    # Key bindings - Using Alt instead of Super for VM compatibility
    $mainMod = ALT

    # Basic bindings
    bind = $mainMod, T, exec, alacritty         # Terminal
    bind = $mainMod, Q, exec, alacritty         # Alternative terminal
    bind = $mainMod, RETURN, exec, alacritty    # Return key for terminal
    bind = $mainMod, C, killactive,
    bind = $mainMod, M, exit,
    bind = $mainMod, E, exec, thunar
    bind = $mainMod, V, togglefloating,
    bind = $mainMod, R, exec, wofi --show drun
    bind = $mainMod, P, pseudo,
    bind = $mainMod, J, togglesplit,

    # Move focus with mainMod + arrow keys
    bind = $mainMod, left, movefocus, l
    bind = $mainMod, right, movefocus, r
    bind = $mainMod, up, movefocus, u
    bind = $mainMod, down, movefocus, d

    # Switch workspaces with mainMod + [0-9]
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6
    bind = $mainMod, 7, workspace, 7
    bind = $mainMod, 8, workspace, 8
    bind = $mainMod, 9, workspace, 9
    bind = $mainMod, 0, workspace, 10

    # Move active window to workspace with mainMod + SHIFT + [0-9]
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6
    bind = $mainMod SHIFT, 7, movetoworkspace, 7
    bind = $mainMod SHIFT, 8, movetoworkspace, 8
    bind = $mainMod SHIFT, 9, movetoworkspace, 9
    bind = $mainMod SHIFT, 0, movetoworkspace, 10

    # Additional bindings with Ctrl for common actions
    bind = CTRL ALT, T, exec, alacritty        # Ctrl+Alt+T for terminal (common shortcut)
    bind = CTRL ALT, L, exec, swaylock-fancy   # Lock screen
    bind = CTRL ALT, DEL, exit,                # Ctrl+Alt+Del to exit (familiar shortcut)

    # Scroll through existing workspaces with mainMod + scroll
    bind = $mainMod, mouse_down, workspace, e+1
    bind = $mainMod, mouse_up, workspace, e-1

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow

    # Screenshot bindings
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
    bind = $mainMod, Print, exec, grim - | wl-copy
    bind = SHIFT, Print, exec, grim - | wl-copy

    # Volume and brightness (if available in VM)
    bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  '';

  # Configure environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # For Electron apps
    MOZ_ENABLE_WAYLAND = "1";  # For Firefox
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
