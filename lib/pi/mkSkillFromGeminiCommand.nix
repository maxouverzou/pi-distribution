# mkSkillFromGeminiCommand - Convert a Gemini CLI command TOML file to an Agent Skill
#
# Gemini CLI commands use TOML format with:
#   description = "Short description"
#   prompt = """Full prompt instructions"""
#
# This builder converts them to Agent Skills format:
#   ---
#   name: skill-name
#   description: Short description
#   ---
#   Full prompt instructions
{
  lib,
  pkgs,
}:

{
  # Required
  name, # Skill name (will be derived from TOML filename if not provided)
  src, # Path to .toml file

  # Optional overrides
  description ? null, # Override description from TOML
  version ? null, # Package version
  license ? null,
  compatibility ? null,
  metadata ? { },

  # Text replacements: { "old string" = "new string"; }
  # Useful for patching paths like ~/.gemini/extensions/foo to nix store paths
  replacements ? { },

  # References: { "filename" = path; } - files to include in references/ directory
  references ? { },

  doCheck ? false, # Disable validation by default (these are conversions)
}:

let
  # Read and parse the TOML file
  tomlContent = builtins.readFile src;

  # Simple TOML parser for our specific format
  # We need to extract `description = "..."` and `prompt = """..."""`
  #
  # This is a simplified parser that handles our specific case:
  # - description is a simple quoted string
  # - prompt is a triple-quoted multiline string

  # Extract description - matches: description = "..."
  descriptionMatch = builtins.match ''.*description[[:space:]]*=[[:space:]]*"([^"]*)".*'' tomlContent;
  parsedDescription =
    if descriptionMatch != null then
      builtins.head descriptionMatch
    else
      throw "Could not parse description from TOML file: ${toString src}";

  # Extract prompt - matches: prompt = """..."""
  # The prompt is everything between the first """ and the last """
  promptMatch = builtins.match ''.*prompt[[:space:]]*=[[:space:]]*"""(.*)"""[[:space:]]*'' tomlContent;
  parsedPrompt =
    if promptMatch != null then
      builtins.head promptMatch
    else
      throw "Could not parse prompt from TOML file: ${toString src}";

  # Apply text replacements to the prompt
  replacementKeys = builtins.attrNames replacements;
  replacementValues = builtins.attrValues replacements;
  patchedPrompt = builtins.replaceStrings replacementKeys replacementValues parsedPrompt;

  # Use provided description or parsed one
  finalDescription = if description != null then description else parsedDescription;

  # Build YAML frontmatter
  yamlValue =
    v:
    if builtins.isString v then
      v
    else if builtins.isBool v then
      (if v then "true" else "false")
    else if builtins.isInt v then
      toString v
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
    description: ${finalDescription}
    ${optionalField "license" license}${optionalField "compatibility" compatibility}${metadataYaml}---
  '';

  # Clean up frontmatter (remove extra blank lines)
  cleanFrontmatter = builtins.replaceStrings [ "\n\n\n" "\n\n---" ] [ "\n" "\n---" ] frontmatter;

  # Final skill content
  skillMdContent = ''
    ${cleanFrontmatter}

    ${patchedPrompt}
  '';

  # Helper to handle reference content (path, store path string, or inline string)
  # For paths and store paths (including subpaths like "${drv}/subdir"), we symlink directly
  # For plain strings, we write them as text files
  buildReference =
    refName: refContent:
    if builtins.isPath refContent then
      refContent
    else if builtins.isString refContent then
      # Check if it's a store path or subpath (starts with /nix/store/)
      if lib.hasPrefix "/nix/store/" refContent || lib.hasPrefix builtins.storeDir refContent then
        refContent
      # Check if it exists as a path (for interpolated derivation paths like "${drv}/subdir")
      else if builtins.pathExists refContent then
        refContent
      else
        # It's an inline string content, write it as a file
        pkgs.writeText refName refContent
    else
      throw "Reference '${refName}' must be a path or string, got: ${builtins.typeOf refContent}";

  builtReferences = lib.mapAttrs buildReference references;

in
pkgs.runCommand "skill-${name}"
  (
    {
      pname = "skill-${name}";
    }
    // lib.optionalAttrs (version != null) { inherit version; }
  )
  ''
  mkdir -p $out
  cat > $out/SKILL.md << 'SKILLEOF'
  ${skillMdContent}
  SKILLEOF

  # Create references directory if we have references
  ${lib.optionalString (references != { }) ''
    mkdir -p $out/references
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (refName: refPath: "ln -s ${refPath} $out/references/${refName}") builtReferences
    )}
  ''}
''
