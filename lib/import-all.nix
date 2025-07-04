# Enhanced import-all.nix utility
# Imports all .nix files from a directory and merges them into a single attribute set
# 
# Usage:
#   import-all.nix "/path/to/dir"                    # Basic usage (backward compatible)
#   import-all.nix { dir = "/path/to/dir"; }         # With options
#   import-all.nix { dir = "/path/to/dir"; merge = (a: b: a // b); }  # Custom merge function

# Function that handles both old and new calling conventions
args:
let
  inherit (builtins) readDir pathExists attrNames isAttrs isString typeOf;
  
  # Handle backward compatibility: accept either a string (directory path) or an attribute set
  config = if isString args then 
    { dir = args; merge = (a: b: a // b); } 
  else if isAttrs args then 
    { dir = args.dir or (throw "import-all.nix: 'dir' parameter is required"); 
      merge = args.merge or (a: b: a // b); }
  else 
    throw "import-all.nix: argument must be either a directory path (string) or an attribute set with 'dir' field";
  
  # Extract configuration
  dir = config.dir;
  mergeFunction = config.merge;
  
  # Validate that the directory exists and is actually a directory
  dirExists = pathExists dir;
  dirType = if dirExists then (readDir dir) else {};
  
  # Get list of files in directory, with better error handling
  files = if dirExists then 
    attrNames dirType
  else 
    throw "import-all.nix: Directory '${toString dir}' does not exist";
  
  # More efficient .nix file filtering using string suffix matching
  # This is more efficient than regex matching for simple suffix checks
  nixFiles = builtins.filter (f: 
    let len = builtins.stringLength f;
    in len > 4 && builtins.substring (len - 4) 4 f == ".nix"
  ) files;
  
  # Enhanced file import with better error messages and context
  importFile = f:
    let 
      filePath = dir + "/${f}";
      val = import filePath;
    in 
      if isAttrs val then 
        val
      else 
        # Enhanced error message with more debugging context
        let
          valType = typeOf val;
          preview = if isString val then 
            " (content preview: \"${builtins.substring 0 50 val}${if builtins.stringLength val > 50 then "..." else ""}\")"
          else "";
        in
          throw ''
            import-all.nix: File does not return an attribute set
            
            Directory: ${toString dir}
            File: ${f}
            Full path: ${toString filePath}
            Expected: attribute set
            Actual: ${valType}${preview}
            
            Each .nix file in the directory must evaluate to an attribute set.
            If you need to import a different type of value, consider wrapping it in an attribute set.
          '';
  
  # Import all files and collect them into a list
  importedFiles = map importFile nixFiles;
  
  # Merge all imported attribute sets using the provided merge function
  # Using foldl' for efficiency with large numbers of files
  merged = builtins.foldl' mergeFunction {} importedFiles;
in
  merged