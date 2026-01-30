# mkSkillWithDeps - Build an Agent Skills compatible skill with npm dependencies
#
# Creates a skill derivation from a directory containing:
# - SKILL.md (required)
# - package.json (required)
# - package-lock.json (required)
# - scripts/ (optional) - JavaScript files copied as-is
# - references/ (optional)
# - assets/ (optional)
#
# Uses buildNpmPackage to install dependencies from npm.
#
# Output structure:
#   $out/ (containing SKILL.md, scripts/, node_modules/, etc.)
#
# Passthru attributes for Home Manager integration:
#   - skillName: the skill name extracted from derivation name
#   - isDirectory: always true for skills with dependencies
{
  lib,
  pkgs,
  skills-ref,
}:

{
  # Required
  src, # Path to directory containing SKILL.md, package.json, package-lock.json
  npmDepsHash, # Hash of npm dependencies (use lib.fakeHash to get the correct value)

  # Optional
  version ? null,
  doCheck ? true, # Run skills-ref validation
  env ? { }, # Environment variables for buildNpmPackage
  ... # Additional buildNpmPackage attributes
}@args:

let
  # Normalize src to string for consistent handling
  srcStr = toString src;

  # Validate source is a directory with required files
  validateSource =
    if builtins.readFileType src != "directory" then
      throw "mkSkillWithDeps: src must be a directory, got file: ${srcStr}"
    else if !builtins.pathExists "${srcStr}/SKILL.md" then
      throw "mkSkillWithDeps: directory '${srcStr}' must contain a SKILL.md file"
    else if !builtins.pathExists "${srcStr}/package.json" then
      throw "mkSkillWithDeps: directory '${srcStr}' must contain a package.json file"
    else if !builtins.pathExists "${srcStr}/package-lock.json" then
      throw "mkSkillWithDeps: directory '${srcStr}' must contain a package-lock.json file"
    else
      true;

  # Filter out custom args that shouldn't be passed to buildNpmPackage
  filteredArgs = builtins.removeAttrs args [ "doCheck" ];

  # Build the skill with npm dependencies
  skillDrv = pkgs.buildNpmPackage (
    {
      pname = "skill-${baseNameOf srcStr}";
      inherit src npmDepsHash;

      # These skills don't have a build step, just install dependencies
      dontNpmBuild = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r . $out/
        runHook postInstall
      '';

      meta = {
        description = "Agent Skills compatible skill: ${baseNameOf srcStr}";
      };
    }
    // lib.optionalAttrs (version != null) { inherit version; }
    // lib.optionalAttrs (env != { }) { inherit env; }
    // filteredArgs
  );

  # Extract skill name from derivation name for passthru
  skillName = lib.removePrefix "skill-" skillDrv.pname;

  # Passthru attributes for Home Manager integration
  passthruAttrs = {
    inherit skillName;
    isDirectory = true;
  };

  # Validated derivation
  validatedDrv = pkgs.runCommand "${skillDrv.pname}-validated"
    {
      nativeBuildInputs = [ skills-ref ];
    }
    ''
      # Copy the skill to output first
      cp -r ${skillDrv} $out
      chmod -R u+w $out

      # Run validation
      # Note: skills-ref expects the directory name to match the skill name
      # So we create a temp directory with the correct name
      tmpdir=$(mktemp -d)
      cp -r ${skillDrv} "$tmpdir/${skillName}"

      echo "Validating skill: ${skillName}"
      if ! skills-ref validate "$tmpdir/${skillName}"; then
        echo "Skill validation failed for: ${skillName}"
        exit 1
      fi
      echo "Skill validation passed: ${skillName}"
    '';

in
assert validateSource;

if doCheck then
  validatedDrv // { passthru = passthruAttrs; }
else
  skillDrv // { passthru = passthruAttrs; }
