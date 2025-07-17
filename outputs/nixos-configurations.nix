inputs:
let
  mkConfigs = import ../lib/mk-configs.nix { lib = inputs.nixpkgs.lib; };
  hosts = mkConfigs.mkHosts ../hosts;
  mkHost = name: hostConfig: inputs.nixpkgs.lib.nixosSystem {
    inherit (hostConfig) system;
    modules = hostConfig.modules ++ [
      inputs.agenix.nixosModules.default
    ];
  };
  allHosts = hosts // {
    installer = {
      system = "x86_64-linux";
      modules = [
        ../hosts/installer/host.nix
      ];
    };
  };
in
{
  builtins.mapAttrs mkHost allHosts
}