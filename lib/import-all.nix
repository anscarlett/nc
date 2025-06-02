# Import all .nix files from a directory and merge them into a single set
dir: let
  inherit (builtins) readDir pathExists map attrNames listToAttrs foldl' intersectAttrs;
  
  # Read all .nix files from the directory
  files = if pathExists dir 
    then attrNames (readDir dir)
    else [];
  
  # Filter for .nix files and remove extension
  nixFiles = map (name: builtins.substring 0 (builtins.stringLength name - 4) name)
    (builtins.filter (name: builtins.match ".*\\.nix" name != null) files);
  
  # Import each file and get its contents
  importFile = name: import (dir + "/${name}.nix");
  
  # Merge all imported files into a single set
  mergeInputs = foldl' (acc: input: acc // input) {};

in
  mergeInputs (map importFile nixFiles)
