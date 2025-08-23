{
  imports = [
    ./browsers
    ./editors
    ./terminals
  ];
  
  options.myHome.desktop = {
    enable = lib.mkEnableOption "desktop applications";
  };
}
