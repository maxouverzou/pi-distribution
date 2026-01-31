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
    home.file.${cfg.configDir} = {
      source = pkgs.mkPiEnv {
        inherit (cfg) skills prompts extensions settings;
      };
      recursive = true;
    };
  };
}
