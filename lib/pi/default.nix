# Pi builders - Agent customization builders for pi coding agent
#
# Exports:
#   - mkSkill: Build Agent Skills compatible skill directories
#   - mkSkillFromGeminiCommand: Convert Gemini CLI command TOML to Agent Skill
#   - mkSkillWithDeps: Build Agent Skills compatible skill with npm dependencies
#   - mkPromptTemplate: Build pi prompt templates
#   - mkExtension: Build pi extensions from TypeScript
#   - mkExtensionWithDeps: Build pi extensions with npm dependencies
{
  lib,
  pkgs,
  mkScript,
  skills-ref,
}:

{
  mkSkill = import ./mkSkill.nix {
    inherit
      lib
      pkgs
      mkScript
      skills-ref
      ;
  };

  mkSkillFromGeminiCommand = import ./mkSkillFromGeminiCommand.nix {
    inherit lib pkgs;
  };

  mkSkillWithDeps = import ./mkSkillWithDeps.nix {
    inherit lib pkgs skills-ref;
  };

  mkPromptTemplate = import ./mkPromptTemplate.nix {
    inherit lib pkgs;
  };

  mkExtension = import ./mkExtension.nix {
    inherit lib pkgs;
  };

  mkExtensionWithDeps = import ./mkExtensionWithDeps.nix {
    inherit lib pkgs;
  };
}
