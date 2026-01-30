# mkSkill - Build an Agent Skills compatible skill directory
#
# Creates a skill directory following the Agent Skills specification:
# https://agentskills.io/specification
{
  lib,
  pkgs,
  mkScript,
  skills-ref,
}:

{
  # Required fields
  name, # Skill name (lowercase, hyphens, max 64 chars)
  description, # What the skill does (max 1024 chars)
  instructions, # Markdown string (body of SKILL.md)

  # Optional frontmatter fields
  version ? null, # Package version
  license ? null,
  compatibility ? null,
  metadata ? { },
  allowedTools ? null, # Space-delimited list of pre-approved tools

  # Pi-specific extensions
  disableModelInvocation ? false, # Hide from system prompt, require /skill:name

  # Resources
  scripts ? { }, # Attrset: filename -> script spec
  references ? { }, # Attrset: filename -> string or path
  assets ? { }, # Attrset: filename -> path

  # Build options
  doCheck ? true, # Run skills-ref validation
}:

let
  # Generate YAML frontmatter
  # We manually construct YAML to avoid dependency on a YAML library
  # and to have precise control over formatting
  yamlValue =
    v:
    if builtins.isString v then
      v
    else if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isInt v then
      toString v
    else if builtins.isAttrs v then
      lib.concatStringsSep "\n" (lib.mapAttrsToList (k: val: "  ${k}: ${yamlValue val}") v)
    else
      toString v;

  optionalField = field: value: lib.optionalString (value != null) "${field}: ${yamlValue value}\n";

  metadataYaml =
    if metadata == { } then
      ""
    else
      "metadata:\n${
        lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "  ${k}: \"${toString v}\"") metadata)
      }\n";

  frontmatter = ''
    ---
    name: ${name}
    description: ${description}
    ${optionalField "license" license}${optionalField "compatibility" compatibility}${metadataYaml}${optionalField "allowed-tools" allowedTools}${lib.optionalString disableModelInvocation "disable-model-invocation: true\n"}---
  '';

  # Clean up frontmatter (remove extra blank lines)
  cleanFrontmatter = builtins.replaceStrings [ "\n\n\n" "\n\n---" ] [ "\n" "\n---" ] frontmatter;

  skillMdContent = ''
    ${cleanFrontmatter}

    ${instructions}
  '';

  # Build individual scripts using mkScript
  builtScripts = lib.mapAttrs (scriptName: spec: mkScript (spec // { name = scriptName; })) scripts;

  # Get the actual binary name from a script derivation
  # For Python scripts, writePython3Bin strips the .py extension
  getScriptBinName =
    scriptName: spec: if spec.type == "python" then lib.removeSuffix ".py" scriptName else scriptName;

  # Helper to copy or write reference files
  buildReference =
    refName: refContent:
    if builtins.isPath refContent || lib.isStorePath refContent then
      refContent
    else
      pkgs.writeText refName refContent;

  builtReferences = lib.mapAttrs buildReference references;

  # Main derivation
  skillDrv = pkgs.runCommand "skill-${name}"
    (
      {
        pname = "skill-${name}";
      }
      // lib.optionalAttrs (version != null) { inherit version; }
    )
    ''
    mkdir -p $out

    # Write SKILL.md
    cat > $out/SKILL.md << 'SKILLEOF'
    ${skillMdContent}
    SKILLEOF

    # Create scripts directory if we have scripts
    ${lib.optionalString (scripts != { }) ''
      mkdir -p $out/scripts
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          scriptName: scriptDrv:
          let
            binName = getScriptBinName scriptName scripts.${scriptName};
          in
          "ln -s ${scriptDrv}/bin/${binName} $out/scripts/${scriptName}"
        ) builtScripts
      )}
    ''}

    # Create references directory if we have references
    ${lib.optionalString (references != { }) ''
      mkdir -p $out/references
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (refName: refPath: "ln -s ${refPath} $out/references/${refName}") builtReferences
      )}
    ''}

    # Create assets directory if we have assets
    ${lib.optionalString (assets != { }) ''
      mkdir -p $out/assets
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (assetName: assetPath: "ln -s ${assetPath} $out/assets/${assetName}") assets
      )}
    ''}
  '';

  # Validated derivation
  validatedDrv =
    pkgs.runCommand "skill-${name}-validated"
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
        cp -r ${skillDrv} "$tmpdir/${name}"

        echo "Validating skill: ${name}"
        if ! skills-ref validate "$tmpdir/${name}"; then
          echo "Skill validation failed for: ${name}"
          exit 1
        fi
        echo "Skill validation passed: ${name}"
      '';

in
if doCheck then validatedDrv else skillDrv
