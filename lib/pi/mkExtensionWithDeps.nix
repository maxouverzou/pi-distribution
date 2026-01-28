# mkExtensionWithDeps - Build a pi extension with npm dependencies
#
# Creates an extension derivation from a directory containing:
# - index.ts (required)
# - package.json (required)
# - package-lock.json (required)
#
# Uses buildNpmPackage to install dependencies from npm.
#
# Output structure:
#   $out/${name}/ (containing index.ts, node_modules, etc.)
#
# Passthru attributes for Home Manager integration:
#   - extensionName: the extension name
#   - extensionPath: relative path within $out (always ${name} for directory extensions)
#   - isDirectoryExtension: always true for this builder
{
  lib,
  pkgs,
}:

{
  # Required
  name, # Extension name
  src, # Path to directory containing index.ts, package.json, package-lock.json
  npmDepsHash, # Hash of npm dependencies (use lib.fakeHash to get the correct value)

  # Optional
  version ? "1.0.0",
}:

let
  # Normalize src to string for consistent handling
  srcStr = toString src;

  # Validate source is a directory with required files
  validateSource =
    if builtins.readFileType src != "directory" then
      throw "mkExtensionWithDeps: src must be a directory, got file: ${srcStr}"
    else if !builtins.pathExists "${srcStr}/index.ts" then
      throw "mkExtensionWithDeps: directory '${srcStr}' must contain an index.ts file"
    else if !builtins.pathExists "${srcStr}/package.json" then
      throw "mkExtensionWithDeps: directory '${srcStr}' must contain a package.json file"
    else if !builtins.pathExists "${srcStr}/package-lock.json" then
      throw "mkExtensionWithDeps: directory '${srcStr}' must contain a package-lock.json file"
    else
      true;

  # Passthru attributes for Home Manager integration
  passthruAttrs = {
    extensionName = name;
    extensionPath = name;
    isDirectory = true;
    isDirectoryExtension = true;
  };

in
assert validateSource;

pkgs.buildNpmPackage {
  pname = "extension-${name}";
  inherit version src npmDepsHash;

  # These extensions don't have a build step
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/${name}
    cp -r . $out/${name}/
    runHook postInstall
  '';

  passthru = passthruAttrs;

  meta = {
    description = "Pi extension: ${name}";
  };
}
