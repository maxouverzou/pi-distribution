# Main library entry point
#
# Provides:
#   - mkScript: Low-level script builder
#   - pi: Pi-specific builders (mkSkill, mkPromptTemplate, mkExtension)
{
  lib,
  pkgs,
  skills-ref ? pkgs.callPackage ../pkgs/skills-ref { },
}:

let
  mkScript = import ./mkScript.nix { inherit lib pkgs; };
in
{
  inherit mkScript;

  pi = import ./pi {
    inherit
      lib
      pkgs
      mkScript
      skills-ref
      ;
  };
}
