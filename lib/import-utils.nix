# Helper functions for importing Nix files
{ lib }:
{
  # Import all .nix files from a directory, excluding default.nix
  # Returns an attrset where keys are filenames (without .nix) and values are the imported contents
  importAll = dir:
    let
      # Get all .nix files
      files = builtins.attrNames (builtins.readDir dir);
      # Filter out default.nix and non-.nix files
      nixFiles = builtins.filter (f: f != "default.nix" && lib.hasSuffix ".nix" f) files;
      # Import each file
      imported = map (f: {
        name = lib.removeSuffix ".nix" f;
        value = import (dir + "/${f}");
      }) nixFiles;
    in
    builtins.listToAttrs imported;

  # Import all outputs from a directory
  # Each output file should export an attribute set
  # Returns a merged attribute set of all outputs
  importOutputs = dir:
    let
      # Get all output files
      outputs = importAll dir;
      # Merge them into a single attribute set
      merged = lib.foldr (name: acc: acc // outputs.${name}) {} (builtins.attrNames outputs);
    in
    merged;

  # Import all inputs from a directory
  # Each input file should export an attribute set with a single input
  # Returns a merged attribute set of all inputs
  importInputs = dir:
    let
      # Get all input files
      inputs = importAll dir;
      # Merge them into a single attribute set
      merged = lib.foldr (name: acc: acc // inputs.${name}) {} (builtins.attrNames inputs);
    in
    merged;
}
