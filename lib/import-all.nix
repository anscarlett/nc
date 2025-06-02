# Import all .nix files from a directory
dir: let
  # Helper function to merge two attribute sets
  recursiveMerge = a: b: 
    let
      f = name:
        if builtins.hasAttr name a && builtins.hasAttr name b &&
           builtins.isAttrs a.${name} && builtins.isAttrs b.${name}
        then recursiveMerge a.${name} b.${name}
        else b.${name};
    in
    a // (builtins.mapAttrs f b);

  # Get all .nix files
  files = if builtins.pathExists dir
    then builtins.attrNames (builtins.readDir dir)
    else [];

  # Filter for .nix files
  nixFiles = builtins.filter (f: builtins.match ".*\.nix" f != null) files;

  # Import each file
  imported = map (f: import (dir + "/${f}")) nixFiles;

in
  # Merge all imported files
  builtins.foldl' recursiveMerge {} imported
