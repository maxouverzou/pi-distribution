# mkExtension - Build a pi extension from TypeScript source
#
# Creates an extension derivation from a .ts file or directory
#
# Output structure:
#   - Single file: $out/${name}.ts
#   - Directory: $out/${name}/ (containing index.ts and other files)
#
# Passthru attributes for Home Manager integration:
#   - extensionName: the extension name
#   - extensionPath: relative path within $out (e.g., "tools.ts" or "plan-mode")
#   - isDirectoryExtension: true if directory, false if single file
{
  lib,
  pkgs,
}:

{
  # Required
  name, # Extension name
  src, # Path or store path to .ts file or directory containing index.ts
}:

let
  # Normalize src to string for consistent handling
  srcStr = toString src;

  # Check if src is a directory
  srcType = builtins.readFileType src;
  isDirectory = srcType == "directory";

  # Check if it's a valid path (either Nix path or store path string)
  isValidSrc = builtins.isPath src || lib.isStorePath srcStr || builtins.pathExists src;

  # Validate source
  validateSource =
    if !isValidSrc then
      throw "Extension src must be a path or store path, got: ${builtins.typeOf src}"
    else if isDirectory then
      if !builtins.pathExists "${srcStr}/index.ts" then
        throw "Extension directory '${srcStr}' must contain an index.ts file"
      else
        true
    else if !lib.hasSuffix ".ts" srcStr then
      throw "Extension file must have .ts extension, got: ${srcStr}"
    else
      true;

  # The relative path within $out where the extension lives
  extensionPath = if isDirectory then name else "${name}.ts";

  # Common passthru attributes for Home Manager integration
  passthruAttrs = {
    extensionName = name;
    inherit extensionPath isDirectory;
    isDirectoryExtension = isDirectory;
  };

in
assert validateSource;

if isDirectory then
  # Directory extension - copy the entire directory into $out/${name}/
  pkgs.runCommand "extension-${name}"
    {
      passthru = passthruAttrs;
    }
    ''
      mkdir -p $out/${name}
      cp -r ${src}/* $out/${name}/
    ''
else
  # Single file extension - copy to $out/${name}.ts
  pkgs.runCommand "extension-${name}"
    {
      passthru = passthruAttrs;
    }
    ''
      mkdir -p $out
      cp ${src} $out/${name}.ts
    ''
