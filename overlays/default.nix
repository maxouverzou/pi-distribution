# Overlay that adds packages and library functions
final: prev:
let
  packages = import ../pkgs { inherit final prev; };

  # Import lib with skills-ref from the packages
  piLib = import ../lib {
    lib = final.lib;
    pkgs = final;
    skills-ref = packages.skills-ref;
  };
in
packages
// {
  # Expose library functions under pkgs.piLib
  piLib = piLib;

  # Also expose at top level for convenience
  inherit (piLib) mkScript;
  inherit (piLib.pi)
    mkSkill
    mkSkillFromGeminiCommand
    mkSkillWithDeps
    mkPromptTemplate
    mkExtension
    mkExtensionWithDeps
    ;
}
