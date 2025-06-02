# Import and merge all outputs
inputs: dir: let
  inherit (builtins) mapAttrs recursiveUpdate;
  
  # Import all output files
  outputs = import ./import-all.nix dir;
  
  # Apply inputs to each output
  applyInputs = _: output: 
    if builtins.isFunction output
    then output inputs
    else output;

  # Convert outputs to a single set
  appliedOutputs = mapAttrs applyInputs outputs;

in
  # Merge all outputs into a single set
  builtins.foldl' recursiveUpdate {} (builtins.attrValues appliedOutputs)
