# Performance optimization helpers
{ lib }:
{
  # Check if a path is being imported multiple times (can cause rebuild issues)
  detectDuplicateImports = configurations:
    let
      extractImports = config: 
        # This would need to be implemented to extract import paths from configs
        [];
      
      allImports = lib.flatten (lib.mapAttrsToList (_: extractImports) configurations);
      importCounts = lib.foldl' (acc: path: 
        acc // { ${path} = (acc.${path} or 0) + 1; }
      ) {} allImports;
      
      duplicates = lib.filterAttrs (_: count: count > 1) importCounts;
    in
      if duplicates == {} then null else duplicates;
      
  # Suggest optimizations for common performance issues
  suggestOptimizations = {
    enableParallelBuilding ? true,
    enableCCache ? false,
    enableDistcc ? false
  }: {
    inherit enableParallelBuilding enableCCache enableDistcc;
    
    # Add suggestions based on system
    suggestions = []
      ++ lib.optional (!enableParallelBuilding) "Enable parallel building for faster compilation"
      ++ lib.optional (!enableCCache) "Consider enabling CCache for C/C++ compilation caching"
      ++ lib.optional (!enableDistcc) "Consider DistCC for distributed compilation";
  };
}
