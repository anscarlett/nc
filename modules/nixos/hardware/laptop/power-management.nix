{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.mySystem.hardware.laptop.powerManagement.enable {
    # CPU frequency scaling
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "ondemand";
      powertop.enable = true;
    };
    
    # Suspend and hibernation
    systemd.sleep.extraConfig = ''
      HibernateDelaySec=3600
      SuspendMode=suspend
      HibernateMode=platform shutdown
    '';
    
    # Power profiles daemon
    services.power-profiles-daemon.enable = true;
    
    # Thermald for Intel CPUs
    services.thermald.enable = lib.mkDefault true;
    
    # Auto-cpufreq as alternative to TLP
    # services.auto-cpufreq = {
    #   enable = true;
    #   settings = {
    #     battery = {
    #       governor = "powersave";
    #       turbo = "never";
    #     };
    #     charger = {
    #       governor = "performance";
    #       turbo = "auto";
    #     };
    #   };
    # };
    
    # ACPI event handling
    services.acpid = {
      enable = true;
      lidEventCommands = ''
        # Suspend on lid close
        LID_STATE=/proc/acpi/button/lid/LID/state
        if [ -f $LID_STATE ]; then
          if grep -q closed $LID_STATE; then
            systemctl suspend
          fi
        fi
      '';
      
      powerEventCommands = ''
        # Handle power button
        systemctl suspend
      '';
    };
    
    # Battery monitoring
    services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "Hibernate";
    };
    
    # Tools for power management
    environment.systemPackages = with pkgs; [
      powertop
      acpi
      lm_sensors
      stress
      s-tui
      turbostat
      intel-gpu-tools
    ];
  };
}
