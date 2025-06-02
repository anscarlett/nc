# Base desktop configuration shared by all desktop environments
{ config, pkgs, lib, ... }: {
  # Base X11 configuration
  services.xserver = {
    enable = true;
    layout = "gb";
    xkbVariant = "";
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable sound with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Base desktop packages that are useful regardless of DE/WM
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    chromium

    # Development
    vscode

    # Terminal
    alacritty    # Modern terminal emulator

    # System
    pavucontrol  # Audio control
    blueman      # Bluetooth manager
    networkmanagerapplet # Network manager tray icon

    # Media
    mpv          # Video player
    imv          # Image viewer
    ffmpeg       # Media converter

    # Utilities
    xclip        # Clipboard support
    flameshot    # Screenshot tool
    libnotify    # Notification library
    xdg-utils    # For xdg-open, etc.
    
    # Archives
    zip
    unzip
    p7zip
  ];

  # Enable common desktop services
  services.udisks2.enable = true;      # Disk management
  services.gvfs.enable = true;         # Trash, MTP, etc.
  services.devmon.enable = true;       # Auto-mount drives
  services.printing.enable = true;      # CUPS
  services.system-config-printer.enable = true;  # Printer settings UI
}
