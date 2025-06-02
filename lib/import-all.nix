dir: let
  inherit (builtins) readDir pathExists attrNames;
  files = if pathExists dir then attrNames (readDir dir) else [];
  nixFiles = builtins.filter (f: builtins.match ".*\\.nix" f != null) files;
  importFile = f:
    let val = import (dir + "/${f}");
    in if builtins.isAttrs val then val
       else abort "File ${dir}/${f} does not return a set, but: ${builtins.typeOf val}";
  merged = builtins.foldl' (a: b: a // b) {} (map importFile nixFiles);
in
  merged