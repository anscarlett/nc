# Host configurations
{
  laptop = {
    system = "x86_64-linux";
    modules = [
      ../configuration.nix
    ];
  };

  # Example of another host with different architecture
  # raspberry-pi = {
  #   system = "aarch64-linux";
  #   modules = [
  #     ../configuration.nix
  #     ./raspberry-pi/hardware-configuration.nix
  #   ];
  # };
}
