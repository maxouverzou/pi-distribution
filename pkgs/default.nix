# Package set for the overlay
# Note: receives both final and prev to avoid infinite recursion
{ final, prev }:
{
  # Use prev for packages that exist in nixpkgs to avoid infinite recursion
  hello = prev.hello;

  # Custom packages use final.callPackage so they can access our overlay additions
  pi-coding-agent = final.callPackage ./pi-coding-agent { };
  skills-ref = final.callPackage ./skills-ref { };

  # Extensions from pi-mono examples
  piExtensions = import ./extensions {
    pkgs = final;
    inherit (final) mkExtension mkExtensionWithDeps;
  };

  # Skills converted from other formats
  piSkills = {
    # Conductor skills from Gemini CLI extension
    conductor = import ./skills/conductor {
      pkgs = final;
      inherit (final) mkSkillFromGeminiCommand;
    };

    # Browser automation skills
    browser = import ./skills/browser-tools {
      pkgs = final;
      inherit (final) mkSkillWithDeps;
    };
  };

  # Prompt templates
  piPrompts = import ./prompts {
    pkgs = final;
  };
}
