{
  imports = [
    ./laptop
    ./desktop
    ./server
  ];
  
  options.mySystem.hardware = {
    enable = lib.mkEnableOption "hardware configuration";
    
    type = lib.mkOption {
      type = lib.types.enum [ "laptop" "desktop" "server" ];
      description = "Hardware type";
    };
  };
  
  config = lib.mkIf config.mySystem.hardware.enable {
    # Auto-enable hardware modules based on type
    mySystem.hardware.laptop.enable = lib.mkIf (config.mySystem.hardware.type == "laptop") true;
    mySystem.hardware.desktop.enable = lib.mkIf (config.mySystem.hardware.type == "desktop") true;
    mySystem.hardware.server.enable = lib.mkIf (config.mySystem.hardware.type == "server") true;
  };
}
