# Home Manager module for pi coding agent
#
# Installs the pi-coding-agent package and manages:
# - Skills in ~/.pi/agent/skills/
# - Prompt templates in ~/.pi/agent/prompts/
# - Extensions in ~/.pi/agent/extensions/
# - Settings in ~/.pi/agent/settings.json (optional)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi;

  # Helper to get skill name from derivation
  # The skill derivation is expected to have SKILL.md at its root
  getSkillName =
    skillDrv:
    let
      # Read the SKILL.md to extract the name from frontmatter
      # For now, we derive the name from the derivation name
      # which follows the pattern "skill-${name}" or "skill-${name}-validated"
      drvName = skillDrv.name or (builtins.baseNameOf skillDrv);
      # Remove "skill-" prefix and "-validated" suffix
      withoutPrefix = lib.removePrefix "skill-" drvName;
      withoutSuffix = lib.removeSuffix "-validated" withoutPrefix;
    in
    withoutSuffix;

  # Helper to get prompt name from derivation
  # Prompt derivations contain ${name}.md at their root
  getPromptName =
    promptDrv:
    let
      # List files in the derivation
      # The prompt file is ${name}.md
      drvName = promptDrv.name or (builtins.baseNameOf promptDrv);
    in
    drvName;

  # Helper to get extension info from derivation
  # Uses passthru attributes if available, falls back to name parsing
  getExtensionInfo =
    extDrv:
    let
      # Try to get from passthru first
      hasPassthru = extDrv ? passthru;
      extName =
        if hasPassthru && extDrv.passthru ? extensionName then
          extDrv.passthru.extensionName
        else
          let
            drvName = extDrv.name or (builtins.baseNameOf extDrv);
            # Remove "extension-" prefix and version suffix
            withoutPrefix = lib.removePrefix "extension-" drvName;
            withoutVersion = builtins.head (lib.splitString "-" withoutPrefix);
          in
          withoutVersion;
      extPath =
        if hasPassthru && extDrv.passthru ? extensionPath then extDrv.passthru.extensionPath else extName;
      isDir =
        if hasPassthru && extDrv.passthru ? isDirectoryExtension then
          extDrv.passthru.isDirectoryExtension
        else
          # Fallback: assume directory if path doesn't end in .ts
          !(lib.hasSuffix ".ts" extPath);
    in
    {
      name = extName;
      path = extPath;
      isDirectory = isDir;
    };

  # Generate home.file entries for skills
  skillFiles = lib.listToAttrs (
    map (skill: {
      name = "${cfg.configDir}/skills/${getSkillName skill}";
      value = {
        source = skill;
        recursive = true;
      };
    }) cfg.skills
  );

  # Generate home.file entries for prompts
  # Prompts are single .md files, we need to link them individually
  promptFiles = lib.listToAttrs (
    map (prompt: {
      name = "${cfg.configDir}/prompts/${getPromptName prompt}.md";
      value = {
        source = "${prompt}/${getPromptName prompt}.md";
      };
    }) cfg.prompts
  );

  # Generate home.file entries for extensions
  # Uses passthru attributes to determine correct symlink structure
  extensionFiles = lib.listToAttrs (
    map (
      ext:
      let
        info = getExtensionInfo ext;
      in
      {
        name = "${cfg.configDir}/extensions/${info.path}";
        value = {
          source = "${ext}/${info.path}";
        }
        // lib.optionalAttrs info.isDirectory { recursive = true; };
      }
    ) cfg.extensions
  );

  # Generate settings.json if settings are provided
  settingsFile = lib.optionalAttrs (cfg.settings != null) {
    "${cfg.configDir}/settings.json" = {
      text = builtins.toJSON cfg.settings;
    };
  };

in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "pi coding agent";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.pi-coding-agent;
      defaultText = lib.literalExpression "pkgs.pi-coding-agent";
      description = ''
        The pi-coding-agent package to install.
        Set to null to skip package installation (e.g., if installed separately).
      '';
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = ".pi/agent";
      description = "Configuration directory relative to home";
      example = ".config/pi";
    };

    settings = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = ''
        Settings for ~/.pi/agent/settings.json.
        Set to null (default) to manage the file manually outside of Nix.
        When set to an attribute set, the file will be generated from it.

        See https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/settings.md
        for available settings.
      '';
      example = lib.literalExpression ''
        {
          defaultProvider = "anthropic";
          defaultModel = "claude-sonnet-4-20250514";
          defaultThinkingLevel = "medium";
          theme = "dark";
          compaction = {
            enabled = true;
            reserveTokens = 16384;
            keepRecentTokens = 20000;
          };
          retry = {
            enabled = true;
            maxRetries = 3;
          };
          enabledModels = [ "claude-*" "gpt-4o" ];
        }
      '';
    };

    skills = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of skill derivations (from mkSkill or mkSkillFromGeminiCommand)";
      example = lib.literalExpression ''
        [
          pkgs.piSkills.conductor.conductor-setup
          (pkgs.mkSkill {
            name = "my-skill";
            description = "Does something useful";
            instructions = "# Instructions here";
          })
        ]
      '';
    };

    prompts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of prompt template derivations (from mkPromptTemplate)";
      example = lib.literalExpression ''
        [
          (pkgs.mkPromptTemplate {
            name = "review";
            description = "Review code changes";
            content = "Review the staged changes...";
          })
        ]
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of extension derivations (from mkExtension or mkExtensionWithDeps)";
      example = lib.literalExpression ''
        [
          pkgs.piExtensions.tools
          pkgs.piExtensions.plan-mode
          pkgs.piExtensions.sandbox
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the pi-coding-agent package if specified
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    # Install skills, prompts, extensions, and optionally settings
    home.file = skillFiles // promptFiles // extensionFiles // settingsFile;
  };
}
