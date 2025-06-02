# Import all .nix files from a directory as a set
dir: let
  inherit (builtins) readDir pathExists map attrNames listToAttrs;
  
  # Read all .nix files from the directory
  files = if pathExists dir 
    then attrNames (readDir dir)
    else [];
  
  # Filter for .nix files and remove extension
  nixFiles = map (name: builtins.substring 0 (builtins.stringLength name - 4) name)
    (builtins.filter (name: builtins.match ".*\\.nix" name != null) files);
  
  # Import each file
  importFile = name: {
    name = builtins.head (builtins.attrNames (import (dir + "/${name}.nix")));
    value = (import (dir + "/${name}.nix"));
  };

in
  # Create a set of all inputs
  builtins.foldl' (a: b: a // b) {} (map (x: x.value) (map importFile nixFiles))
