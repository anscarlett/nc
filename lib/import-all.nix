# Import all .nix files from a directory
dir: let
  # Get all .nix files
  files = if builtins.pathExists dir
    then builtins.attrNames (builtins.readDir dir)
    else [];

  # Filter for .nix files
  nixFiles = builtins.filter (f: builtins.match ".*\.nix" f != null) files;

  # Import each file
  imported = map (f: import (dir + "/${f}")) nixFiles;

  # Merge all imported files
  mergeInputs = builtins.foldl' (acc: input: acc // input) {};

in
  mergeInputs imported
